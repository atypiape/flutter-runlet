"""在已推送的任务 worktree 中创建或恢复指向 dev 的 PR。"""

import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import subprocess
import sys
from tempfile import TemporaryDirectory


queue = runpy.run_path(str(Path(__file__).with_name("verify-issue-queue.py")))
REPO = queue["REPO"]
TASK_LABELS = queue["TASK_LABELS"]
get = queue["get"]
gh = queue["gh_json"]
WORKING = "task:working"
REVIEW = "task:review"
BRANCH_TYPES = "feat|fix|docs|refactor|perf|test|chore"


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def git(*args):
    result = subprocess.run(
        ["git", *args], capture_output=True, text=True, encoding="utf-8", timeout=15,
    )
    require(result.returncode == 0, "请从任务的 Git worktree 运行。")
    return result.stdout.strip()


def issue_labels(args):
    issue = get(f"issues/{args.issue}")
    require("pull_request" not in issue and issue["state"] == "open", "任务须为开放的 Issue。")
    spec = json.dumps([issue["title"], issue["body"]], ensure_ascii=False)
    require(hashlib.sha256(spec.encode("utf-8")).hexdigest() == args.spec,
            "Issue 规格已变化，请重新核对批准。")
    labels = {label["name"] for label in issue["labels"]} & TASK_LABELS
    require(labels in ({WORKING}, {REVIEW}, {WORKING, REVIEW}),
            "Issue 未处于开发、审查或可恢复的标签状态。")
    return labels


def find_pr(branch):
    owner = REPO.split("/")[0]
    pages = gh("--method", "GET", "--paginate", "--slurp", f"repos/{REPO}/pulls",
               "-f", "state=all", "-f", f"head={owner}:{branch}", "-F", "per_page=100")
    require(isinstance(pages, list)
            and all(isinstance(page, list) and all(isinstance(pr, dict) for pr in page) for page in pages),
            "无法确认历史 PR 查询结果，请重跑。")
    pulls = [pr for page in pages for pr in page]
    require(len(pulls) <= 1, "该任务分支存在多个 PR，请人工核对。")
    return pulls[0] if pulls else None


def check_pr(pr, branch, head, author, reference):
    require(
        pr["state"] == "open" and not pr["draft"]
        and (pr["head"]["repo"] or {}).get("full_name") == REPO
        and pr["head"]["ref"] == branch and pr["head"]["sha"] == head
        and pr["base"]["repo"]["full_name"] == REPO and pr["base"]["ref"] == "dev"
        and pr["user"]["id"] == author and reference in (pr["body"] or "").splitlines(),
        "已有 PR 的状态、来源、提交、目标、作者或 Issue 引用不符，请人工核对。",
    )


def create_pr(args, branch, head, reference):
    require(args.title and args.body_file, "首次创建须提供 --title 和 --body-file。")
    body_file = args.body_file.resolve()
    body = body_file.read_bytes().decode("utf-8")
    require(reference in body.splitlines(), f"PR 正文须单独一行写明 {reference}。")
    require(get(f"git/ref/heads/{branch}")["object"]["sha"] == head,
            "远端任务分支与本地 HEAD 不同，请先核对并推送验证过的提交。")
    require(issue_labels(args) == {WORKING}, "Issue 已变化，请重新核对领取状态。")
    # Pass the verified text through a private temporary file, without exposing it in argv.
    with TemporaryDirectory(prefix="flutter-runlet-pr-") as folder:
        verified_body = Path(folder) / "body.md"
        verified_body.write_bytes(body.encode("utf-8"))
        return gh("--method", "POST", f"repos/{REPO}/pulls",
                  "-f", "base=dev", "-f", f"head={branch}", "-f", f"title={args.title}",
                  "-F", f"body=@{verified_body}")


def finish_handoff(args):
    labels = issue_labels(args)
    path = f"repos/{REPO}/issues/{args.issue}/labels"
    if labels == {WORKING}:
        gh("--method", "POST", path, "-f", f"labels[]={REVIEW}")
        labels = issue_labels(args)
    if labels == {WORKING, REVIEW}:
        gh("--method", "DELETE", f"{path}/task%3Aworking")
        labels = issue_labels(args)
    require(labels == {REVIEW}, "PR 已确认，Issue 标签尚未收尾。请用同一任务重跑。")


def run(args):
    branch = git("branch", "--show-current")
    require(re.fullmatch(rf"({BRANCH_TYPES})/issue-{args.issue}-[a-z0-9-]+", branch),
            "当前分支须为对应 Issue 的合规任务分支。")
    require(not git("status", "--porcelain"), "任务 worktree 须干净。")
    head = git("rev-parse", "HEAD")
    labels = issue_labels(args)
    author = gh("--method", "GET", "user")["id"]
    reference = f"Refs #{args.issue}"
    pr = find_pr(branch)
    action = "reused"
    if pr is None:
        require(labels == {WORKING}, "审查状态缺少匹配的 PR，请人工核对。")
        pr = create_pr(args, branch, head, reference)
        action = "created"

    check_pr(pr, branch, head, author, reference)
    pr = get(f"pulls/{pr['number']}")
    check_pr(pr, branch, head, author, reference)
    finish_handoff(args)
    return {"action": action, "issue": args.issue, "pr": pr["number"],
            "url": pr["html_url"], "head": head}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--issue", type=int, required=True, help="已领取的 Issue 编号")
    parser.add_argument("--spec", required=True, help="领取时记录的 spec_sha256")
    parser.add_argument("--title", help="首次创建时使用的 PR 标题")
    parser.add_argument("--body-file", type=Path, help="首次创建时使用的 PR 正文文件")
    args = parser.parse_args()
    if args.issue < 1 or not re.fullmatch(r"[0-9a-f]{64}", args.spec):
        parser.error("请提供有效的 Issue 编号和规格摘要。")
    try:
        print(json.dumps(run(args), ensure_ascii=False))
    except (OSError, RuntimeError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print(f"PR 流程停止：{error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

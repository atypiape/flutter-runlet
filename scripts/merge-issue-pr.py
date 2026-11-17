"""核验已审查的 Issue PR，可显式执行 Squash 和 Issue 收尾。"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import runpy
import subprocess
import sys
from tempfile import NamedTemporaryFile


queue = runpy.run_path(str(Path(__file__).with_name("verify-issue-queue.py")))
REPO = queue["REPO"]
TASK_LABELS = queue["TASK_LABELS"]
APPROVER_IDS = queue["APPROVER_IDS"]
get = queue["get"]
gh = queue["gh_json"]
event_order = queue["event_order"]
WORKFLOWS = {
    "branch-policy.yml": "branch-policy (dev)",
    "ci.yml": "macOS build and test",
}
ACTIONS_APP = 15368
SHA = re.compile(r"[0-9a-f]{40}")
SNAPSHOT = ("pr", "issue", "author", "head", "base", "test_merge", "spec")


def require(condition, reason):
    if not condition:
        raise RuntimeError(reason)


def check_pr(args, pr, *, for_merge=True):
    branch = rf"(feat|fix|docs|refactor|perf|test|chore)/issue-{args.issue}-[a-z0-9-]+"
    require(
        pr["base"]["repo"]["full_name"] == REPO and pr["base"]["ref"] == "dev"
        and pr["head"]["sha"] == args.head and re.fullmatch(branch, pr["head"]["ref"])
        and f"Refs #{args.issue}" in (pr["body"] or "").splitlines()
        and pr["user"]["type"] == "User" and pr["user"]["id"] == args.author,
        "PR 来源、目标、Issue 引用或已审查的源提交不匹配。",
    )
    if not pr["merged"]:
        require(
            pr["head"]["repo"]["full_name"] == REPO and pr["base"]["sha"] == args.base
            and pr["state"] == "open" and not pr["draft"]
            and pr["merge_commit_sha"] == args.test_merge,
            "PR 状态、审查基线或拟合入提交已变化。",
        )
        if for_merge:
            require(pr["mergeable_state"] == "clean" and pr["mergeable"] is True,
                    "PR 仍有合并阻塞。")


def check_issue(args, issue, merged):
    digest = hashlib.sha256(json.dumps(
        [issue["title"], issue["body"]], ensure_ascii=False,
    ).encode("utf-8")).hexdigest()
    labels = {label["name"] for label in issue["labels"]} & TASK_LABELS
    require("pull_request" not in issue and digest == args.spec, "Issue 规格已变化。")
    if merged and issue["state"] == "closed":
        require(issue["state_reason"] == "completed" and labels in (set(), {"task:review"}),
                "关闭原因或 Issue 标签需要人工核对。")
    else:
        require(issue["state"] == "open" and labels == {"task:review"},
                "Issue 当前未授权进入合并阶段。")
    return labels


def check_approval(args):
    events = get(f"issues/{args.issue}/events?per_page=100", paginate=True)
    approval = max(
        (event for event in events if event["event"] == "labeled"
         and event["label"]["name"] == "task:ready"),
        key=event_order, default=None,
    )
    actor = (approval["actor"] or {}) if approval else {}
    require(approval and approval["id"] == args.approval_event
            and actor.get("type") == "User" and actor.get("id") in APPROVER_IDS,
            "审查记录中的 Issue 批准已变化或无法核实。")
    approved = event_order(approval)
    for event in events:
        supersedes = event["event"] in {"closed", "reopened", "transferred", "renamed"} or (
            event["event"] == "labeled" and event["label"]["name"] == "task:blocked"
        )
        require(not supersedes or event_order(event) <= approved,
                "批准后 Issue 曾被阻塞、关闭或改名，请重新批准。")


def record_review(args):
    pr, issue = get(f"pulls/{args.pr}"), get(f"issues/{args.issue}")
    require(not pr["merged"], "请在 PR 合并前记录审查。")
    check_pr(args, pr, for_merge=False)
    check_issue(args, issue, merged=False)
    check_approval(args)
    evidence = {
        "version": 1, "repo": REPO, **{name: getattr(args, name) for name in SNAPSHOT},
        "approval_event": args.approval_event, "summary": args.summary,
    }
    target = args.record_review
    target.parent.mkdir(parents=True, exist_ok=True)
    # A crash leaves either the previous record or the complete new one.
    with NamedTemporaryFile(mode="w", encoding="utf-8", dir=target.parent, delete=False) as output:
        temporary = Path(output.name)
        try:
            json.dump(evidence, output, ensure_ascii=False, indent=2)
            output.write("\n")
            output.close()
            os.replace(temporary, target)
        finally:
            temporary.unlink(missing_ok=True)
    return {"pr": args.pr, "issue": args.issue, "state": "review-recorded"}


def use_review_file(args):
    evidence = json.loads(args.review_file.read_text(encoding="utf-8"))
    require(isinstance(evidence, dict) and evidence.get("version") == 1
            and evidence.get("repo") == REPO, "审查记录格式或仓库不符。")
    for name in (*SNAPSHOT, "approval_event", "summary"):
        setattr(args, name, evidence.get(name))


def validate_snapshot(args):
    require(all(type(getattr(args, name)) is int and getattr(args, name) > 0
                for name in ("pr", "issue", "author")),
            "请提供有效的 PR、Issue 和作者编号。")
    require(all(isinstance(sha, str) and SHA.fullmatch(sha)
                for sha in (args.head, args.base, args.test_merge))
            and isinstance(args.spec, str) and re.fullmatch(r"[0-9a-f]{64}", args.spec),
            "请提供有效的审查提交和规格摘要。")
    if args.record_review or args.review_file:
        require(type(args.approval_event) is int and args.approval_event > 0
                and isinstance(args.summary, str) and args.summary.strip(),
                "审查记录须包含批准事件和审查结论。")


def check_rules(strict):
    rules = get("rules/branches/dev")
    required = [rule["parameters"] for rule in rules if rule["type"] == "required_status_checks"]
    names = {(check["context"], check["integration_id"])
             for params in required for check in params["required_status_checks"]}
    require({(name, ACTIONS_APP) for name in WORKFLOWS.values()} <= names,
            "dev 缺少约定的 GitHub Actions 必需检查。")
    require(any(rule["type"] == "pull_request"
                and rule["parameters"]["allowed_merge_methods"] == ["squash"] for rule in rules),
            "dev 未强制通过 Squash PR 合入。")
    if strict:
        require(any(params["strict_required_status_checks_policy"] for params in required),
                "定时合并需要 dev 启用「分支必须为最新」。")


def verified_runs(args):
    verified = {}
    for workflow, name in WORKFLOWS.items():
        pages = gh("--method", "GET", "--paginate", "--slurp",
                   f"repos/{REPO}/actions/workflows/{workflow}/runs",
                   "-f", "event=pull_request", "-f", f"head_sha={args.head}", "-F", "per_page=100")
        prefixes = tuple(f"[PR #{args.pr}] [{kind} {args.test_merge}] "
                         for kind in ("validate", "metadata"))
        valid = [run for page in pages for run in page["workflow_runs"]
                 if run["head_sha"] == args.head and run["event"] == "pull_request"
                 and run["display_title"].startswith(prefixes)]
        run = max(valid, key=lambda run: run["run_number"], default=None)
        require(run and run["status"] == "completed" and run["conclusion"] == "success",
                f"当前拟合入提交缺少成功的 {name} 运行。")
        jobs = get(f"actions/runs/{run['id']}/jobs?filter=latest&per_page=100")["jobs"]
        require(any(job["name"] == name and job["head_sha"] == args.head
                    and job["status"] == "completed" and job["conclusion"] == "success"
                    for job in jobs), f"当前运行缺少成功的 {name} 作业。")
        verified[name] = run["id"]
    return verified


def close_task(path, issue, labels):
    if issue["state"] == "open":
        closed = gh("--method", "PATCH", f"repos/{REPO}/{path}",
                    "-f", "state=closed", "-f", "state_reason=completed")
        require(closed["state"] == "closed" and closed["state_reason"] == "completed",
                "合并已完成，Issue 关单结果需核对。")
    if "task:review" in labels:
        subprocess.run(
            ["gh", "issue", "edit", str(issue["number"]), "--repo", REPO,
             "--remove-label", "task:review"],
            check=True, capture_output=True, timeout=45,
        )


def run(args):
    pr_path, issue_path = f"pulls/{args.pr}", f"issues/{args.issue}"
    pr, issue = get(pr_path), get(issue_path)
    check_pr(args, pr)
    labels = check_issue(args, issue, pr["merged"])
    result = {"pr": args.pr, "issue": args.issue}
    if not pr["merged"]:
        if getattr(args, "approval_event", None):
            check_approval(args)
        check_rules(args.require_strict)
        parents = [parent["sha"] for parent in get(f"commits/{args.test_merge}")["parents"]]
        require(parents == [args.base, args.head], "拟合入提交与审查时的基线和源提交不符。")
        result["checks"] = verified_runs(args)
        # Recheck after reading CI evidence. GitHub also compares the head on merge.
        check_pr(args, get(pr_path))
        check_issue(args, get(issue_path), merged=False)
        if args.apply and getattr(args, "approval_event", None):
            check_approval(args)
        require(get("git/ref/heads/dev")["object"]["sha"] == args.base,
                "dev 已前进，需要重新审查并验证。")
        if not args.apply:
            return {**result, "state": "ready"}
        response = gh("--method", "PUT", f"repos/{REPO}/{pr_path}/merge",
                      "-f", f"sha={args.head}", "-f", "merge_method=squash")
        require(response["merged"] is True, "GitHub 未确认合并。")
        pr = get(pr_path)
        require(pr["merged"] is True and pr["merge_commit_sha"] == response["sha"],
                "合并结果需重新核对，Issue 保持待审查。")
        check_pr(args, pr)

    result["sha"] = pr["merge_commit_sha"]
    if args.apply:
        issue = get(issue_path)
        labels = check_issue(args, issue, merged=True)
        close_task(issue_path, issue, labels)
        issue = get(issue_path)
        require(issue["state"] == "closed" and not check_issue(args, issue, merged=True),
                "合并已完成，Issue 关单或标签清理需重跑。")
    return {**result, "state": "merged"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("pr", "issue", "author"):
        parser.add_argument(f"--{name}", type=int)
    for name in ("head", "base", "test-merge", "spec"):
        parser.add_argument(f"--{name}")
    review = parser.add_mutually_exclusive_group()
    review.add_argument("--record-review", type=Path, help="保存已通过的独立审查")
    review.add_argument("--review-file", type=Path, help="从记录读取合并核验参数")
    parser.add_argument("--approval-event", type=int, help="领取时记录的批准事件编号")
    parser.add_argument("--summary", help="独立审查结论与验收证据")
    parser.add_argument("--apply", action="store_true", help="执行合并或恢复关单")
    parser.add_argument("--require-strict", action="store_true", help="定时合并要求严格基线检查")
    args = parser.parse_args()
    if args.record_review and (args.apply or args.require_strict):
        parser.error("记录审查与执行合并是独立操作。")
    if args.require_strict and not args.review_file:
        parser.error("定时核验与合并须提供 --review-file。")
    if args.review_file and any(getattr(args, name) is not None
                                for name in (*SNAPSHOT, "approval_event", "summary")):
        parser.error("使用 --review-file 时请从记录提供审查参数。")
    if not args.record_review and (args.approval_event is not None or args.summary is not None):
        parser.error("请使用 --record-review 保存批准事件与审查结论。")
    try:
        if args.review_file:
            use_review_file(args)
        validate_snapshot(args)
        result = record_review(args) if args.record_review else run(args)
        print(json.dumps(result, ensure_ascii=False))
    except (RuntimeError, OSError, KeyError, TypeError, ValueError, AttributeError, subprocess.SubprocessError) as exc:
        print(f"合并流程停止：{exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

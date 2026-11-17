"""核验 FlutterRunlet 的 Issue 领取队列，输出只读 JSON 快照。"""

import argparse
from datetime import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time


REPO = "atypiape/flutter-runlet"
APPROVER_IDS = {22855313}  # atypiape，使用稳定的 GitHub 账号 ID。
READY = "task:ready"
ACTIVE = ("task:working", "task:review")
BLOCKED = "task:blocked"
TASK_LABELS = {READY, *ACTIVE, BLOCKED}
TASK_TYPES = {"文档", "XCTest 回归测试", "Swift 纯逻辑修复"}
HOOK_DIR = ".githooks"
PUSH_HOOK = f"{HOOK_DIR}/pre-push"
RETRYABLE_HTTP = {408, 500, 502, 503, 504}
TRANSPORT_FAILURE = re.compile(
    r"\bEOF\b|(?:i/o|TLS handshake) timeout|timed out|no such host|"
    r"temporary failure in name resolution|connection (?:reset|refused)|network is unreachable",
    re.IGNORECASE,
)
ISSUE_EDIT_QUERY = """
query($id: ID!) {
  node(id: $id) {
    ... on Issue { title body state lastEditedAt }
  }
}
"""


class Ineligible(Exception):
    pass


class GitHubError(RuntimeError):
    def __init__(self, request, attempt, *, returncode=None, stderr=""):
        match = re.search(r"\(HTTP ([0-9]{3})\)", stderr)
        self.status = int(match[1]) if match else None
        self.transient = self.status in RETRYABLE_HTTP
        hint = ""
        if self.status:
            detail = f"HTTP {self.status}"
            if self.status == 401:
                hint = " 请检查 gh 登录状态。"
            elif self.status in {403, 429}:
                hint = " 请检查权限和 GitHub API 限流状态。"
        elif returncode is None:
            detail = "gh 请求超时"
            self.transient = True
        else:
            detail = f"gh 退出码 {returncode}"
            if TRANSPORT_FAILURE.search(stderr):
                detail += "，网络连接异常"
                self.transient = True
            elif "gh auth login" in stderr:
                hint = " 请检查 gh 登录状态。"
        retry = "，已重试一次" if attempt == 2 else ""
        super().__init__(f"GitHub 请求失败（{request}，{detail}{retry}）。{hint}")


def gh_json(*args):
    if args[0] == "--method":
        method = args[1]
        endpoint = next(arg for arg in args[2:] if not arg.startswith("--")).partition("?")[0]
        request = f"{method} {endpoint}"
        read_only = method == "GET"
    else:
        request = args[0]
        read_only = args[:3] == ("graphql", "-f", f"query={ISSUE_EDIT_QUERY}")

    command = ["gh", "api", "--hostname", "github.com", *args]
    for attempt in (1, 2):
        # Avoid echoing raw gh output, which can include remote content or credentials.
        try:
            result = subprocess.run(
                command, capture_output=True, text=True, encoding="utf-8", timeout=45,
            )
        except subprocess.TimeoutExpired:
            error = GitHubError(request, attempt)
        else:
            if not result.returncode:
                return json.loads(result.stdout)
            error = GitHubError(request, attempt, returncode=result.returncode, stderr=result.stderr)

        if attempt == 2 or not read_only or not error.transient:
            raise error
        time.sleep(1)


def read_git(*args, error):
    result = subprocess.run(["git", *args], capture_output=True, timeout=15)
    if result.returncode != 0:
        raise RuntimeError(error)
    return result.stdout


def check_origin():
    accepted = {
        f"https://github.com/{REPO}", f"git@github.com:{REPO}",
        f"ssh://git@github.com/{REPO}", f"ssh://git@ssh.github.com:443/{REPO}",
    }
    for mode, flags in (("获取", ()), ("推送", ("--push",))):
        urls = read_git("remote", "get-url", *flags, "--all", "origin",
                        error="无法读取 origin。请在 FlutterRunlet 工作区运行。")
        normalized = [url.rstrip("/").lower().removesuffix(".git")
                      for url in urls.decode("utf-8").splitlines()]
        if len(normalized) != 1 or normalized[0] not in accepted:
            raise RuntimeError(f"origin {mode}地址与 {REPO} 不符。")


def check_github_context():
    check_origin()
    actor = gh_json("--method", "GET", "user")
    if actor.get("type") != "User" or actor.get("id") not in APPROVER_IDS:
        raise RuntimeError("当前 gh 登录身份不在 FlutterRunlet 定时任务允许名单中。")
    existing = {label["name"] for label in get("labels?per_page=100", paginate=True)}
    missing = TASK_LABELS - existing
    if missing:
        raise RuntimeError(
            f"仓库缺少任务标签：{', '.join(sorted(missing))}。暂停定时任务后运行 "
            f"bash scripts/create-github-labels.sh --repo {REPO}，核对受影响的 Issue 后再恢复。"
        )
    return {"repository": REPO, "github_user": actor["login"]}


def check_push_hook():
    check_origin()
    hooks = read_git("config", "--get", "core.hooksPath",
                     error="未配置 core.hooksPath。").decode("utf-8").strip()
    if hooks != HOOK_DIR:
        raise RuntimeError(f"core.hooksPath 须指向 {HOOK_DIR}。")
    toplevel = read_git("rev-parse", "--show-toplevel", error="无法找到任务 worktree。")
    hook = Path(os.fsdecode(toplevel.rstrip(b"\n"))) / PUSH_HOOK
    if not hook.is_file() or hook.is_symlink() or not os.access(hook, os.X_OK):
        raise RuntimeError(f"{PUSH_HOOK} 须是可执行的普通文件。")
    expected = read_git("--no-replace-objects", "show", f"refs/remotes/origin/dev:{PUSH_HOOK}",
                        error=f"无法从 origin/dev 读取可信的 {PUSH_HOOK}。")
    if hook.read_bytes() != expected:
        raise RuntimeError(f"{PUSH_HOOK} 与 origin/dev 的版本不同。")
    return {"repository": REPO, "hook": PUSH_HOOK, "status": "ready"}


def get(path, *, paginate=False):
    flags = ("--paginate", "--slurp") if paginate else ()
    result = gh_json("--method", "GET", *flags, f"repos/{REPO}/{path}")
    if paginate:
        return [item for page in result for item in page]
    return result


def open_with_label(label):
    return [
        item for item in get(
            f"issues?state=open&labels={label}&per_page=100", paginate=True,
        )
        if "pull_request" not in item
    ]


def timestamp(value):
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def check_declared_fields(body):
    sections = re.split(r"(?m)^#{1,6}[ \t]+([^\n]+)\n", (body or "").replace("\r\n", "\n"))
    dependencies = []
    for heading, value in zip(sections[1::2], sections[2::2]):
        heading, value = heading.strip(), value.strip()
        if value in {"", "_No response_"}:
            continue
        if heading == "任务类型" and value not in TASK_TYPES:
            raise Ineligible("任务类型需要人工处理。")
        if heading != "前置 Issue" or value == "无":
            continue
        for reference in filter(None, map(str.strip, re.split(r"[,，\n]", value))):
            match = re.fullmatch(r"(?:[-*]\s+|\d+\.\s+)?#([1-9][0-9]*)", reference)
            if not match:
                raise Ineligible("无法核实正文声明的前置 Issue，请填写本仓库编号。")
            dependencies.append(int(match[1]))
    return list(dict.fromkeys(dependencies))


def event_order(event):
    return timestamp(event["created_at"]), event["id"]


def approval_for(issue):
    events = get(f"issues/{issue['number']}/events?per_page=100", paginate=True)
    ready_events = [
        event for event in events
        if event["event"] in {"labeled", "unlabeled"} and event["label"]["name"] == READY
    ]
    approval = max(ready_events, key=event_order, default=None)
    if not approval or approval["event"] != "labeled":
        raise Ineligible("找不到生效的 task:ready 贴标记录。")
    actor = approval["actor"] or {}
    if actor.get("type") != "User" or actor.get("id") not in APPROVER_IDS:
        raise Ineligible("最近一次 task:ready 不是由已授权维护者添加。")
    approved_order = event_order(approval)
    for event in events:
        invalidates_approval = event["event"] in {"renamed", "reopened", "transferred"} or (
            event["event"] == "labeled" and event["label"]["name"] in {*ACTIVE, BLOCKED}
        )
        if invalidates_approval and event_order(event) > approved_order:
            raise Ineligible("批准后标题或任务状态有变动，请重新添加 task:ready。")

    response = gh_json("graphql", "-f", f"query={ISSUE_EDIT_QUERY}", "-f", f"id={issue['node_id']}")
    current = response["data"]["node"]
    if (not current or current["state"] != "OPEN" or current["title"] != issue["title"]
            or (current["body"] or "") != (issue["body"] or "")):
        raise Ineligible("Issue 已变化或无法核对，请重新运行核验。")
    edited_at = current["lastEditedAt"]
    # GitHub reports seconds. A body edit in the same second cannot prove prior approval.
    if edited_at and timestamp(edited_at) >= approved_order[0]:
        raise Ineligible("批准后正文有修改或时间无法区分，请重新添加 task:ready。")
    return approval


def completed(issue):
    return issue["state"] == "closed" and issue["state_reason"] == "completed"


def check_dependencies(number, dependencies):
    for dependency in dependencies:
        try:
            prereq = get(f"issues/{dependency}")
        except GitHubError as error:
            if error.status != 404:
                raise
            raise Ineligible(f"无法读取前置 Issue #{dependency}。") from error
        if "pull_request" in prereq or not completed(prereq):
            raise Ineligible(f"前置 Issue #{dependency} 尚未完成或对应 PR。")
    native = get(f"issues/{number}/dependencies/blocked_by?per_page=100", paginate=True)
    if any(not completed(prereq) for prereq in native):
        raise Ineligible("GitHub 标记的阻塞 Issue 尚未完成。")


def check_issue(issue):
    number = issue["number"]
    try:
        if "pull_request" in issue:
            raise Ineligible("该编号对应 PR。")
        if issue["state"] != "open":
            raise Ineligible("Issue 已关闭。")
        if {label["name"] for label in issue["labels"]} & TASK_LABELS != {READY}:
            raise Ineligible("领取时四个任务标签中只能有 task:ready。")
        dependencies = check_declared_fields(issue["body"])
        if number in dependencies:
            raise Ineligible("Issue 不能依赖自身。")
        approval = approval_for(issue)
        check_dependencies(number, dependencies)
    except Ineligible as error:
        return {"number": number, "eligible": False, "reason": str(error)}

    spec = json.dumps([issue["title"], issue["body"]], ensure_ascii=False)
    return {
        "number": number,
        "eligible": True,
        "approved_at": approval["created_at"],
        "approval_event_id": approval["id"],
        "spec_sha256": hashlib.sha256(spec.encode("utf-8")).hexdigest(),
    }


def check_queue(number=None, *, skip=()):
    active = sorted({item["number"] for label in ACTIVE for item in open_with_label(label)})
    result = {"candidate": None, "active": active, "checked": []}
    if active and number is None:
        return result
    numbers = [number] if number is not None else [
        item["number"] for item in sorted(
            open_with_label(READY), key=lambda item: (timestamp(item["created_at"]), item["number"]),
        ) if item["number"] not in skip
    ]
    for issue_number in numbers:
        checked = check_issue(get(f"issues/{issue_number}"))
        result["checked"].append(checked)
        if checked["eligible"] and not active:
            result["candidate"] = issue_number
            break
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--issue", type=int, help="诊断指定 Issue 编号")
    parser.add_argument("--skip", type=int, action="append", default=[],
                        help="搜索队列时跳过本轮已评估的 Issue，可重复指定")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--preflight", action="store_true", help="核对仓库和 gh 身份后查询队列")
    mode.add_argument("--check-push-hook", action="store_true", help="只读检查当前 worktree 的推送 Hook")
    args = parser.parse_args()
    if args.issue is not None and args.issue < 1:
        parser.error("Issue 编号须为正整数。")
    if args.check_push_hook and args.issue is not None:
        parser.error("--check-push-hook 无需指定 Issue。")
    if args.skip and (args.issue is not None or args.check_push_hook or min(args.skip) < 1):
        parser.error("--skip 仅用于搜索队列，须传入正整数。")
    try:
        if args.check_push_hook:
            result = check_push_hook()
        else:
            context = check_github_context() if args.preflight else None
            result = check_queue(args.issue, skip=set(args.skip))
            if context:
                result["preflight"] = context
    except (OSError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(f"核验失败：{error}", file=sys.stderr)
        return 1
    except (KeyError, TypeError, ValueError):
        print("核验失败：GitHub 响应缺少所需字段或格式异常。", file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())

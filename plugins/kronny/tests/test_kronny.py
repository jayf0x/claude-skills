#!/usr/bin/env python3
"""Tests for kronny hook and CLI.

Run: python3 tests/test_kronny.py
"""
import json
import os
import subprocess
import sys
import tempfile
import time
import unittest

TESTS_DIR = os.path.dirname(os.path.abspath(__file__))
PLUGIN_DIR = os.path.dirname(TESTS_DIR)
HOOK = os.path.join(PLUGIN_DIR, "hooks", "kronny-hook.py")
CLI = os.path.join(PLUGIN_DIR, "scripts", "kronny.py")


class TestHook(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.state_file = os.path.join(self.tmp, "state.json")
        self.env = {**os.environ, "KRONNY_STATE_FILE": self.state_file}

    def _run_hook(self, tool_call):
        return subprocess.run(
            [sys.executable, HOOK],
            input=json.dumps(tool_call),
            capture_output=True,
            text=True,
            env=self.env,
        )

    def _write_state(self, state):
        with open(self.state_file, "w") as f:
            json.dump(state, f)

    def _read_state(self):
        with open(self.state_file) as f:
            return json.load(f)

    # ── no state ────────────────────────────────────────────────────────────

    def test_no_state_file_exits_zero_no_output(self):
        r = self._run_hook({"tool_name": "Bash", "tool_input": {"command": "ls"}})
        self.assertEqual(r.returncode, 0)
        self.assertEqual(r.stdout.strip(), "")

    # ── active window ────────────────────────────────────────────────────────

    def _decision(self, stdout):
        return json.loads(stdout).get("hookSpecificOutput", {}).get("permissionDecision")

    def test_active_window_wildcard_approves_bash(self):
        self._write_state({"expires_at": int(time.time()) + 300, "pattern": "*", "notified": False})
        r = self._run_hook({"tool_name": "Bash", "tool_input": {"command": "ls -la"}})
        self.assertEqual(r.returncode, 0)
        self.assertEqual(self._decision(r.stdout), "allow")

    def test_active_window_wildcard_approves_non_bash(self):
        self._write_state({"expires_at": int(time.time()) + 300, "pattern": "*", "notified": False})
        r = self._run_hook({"tool_name": "Read", "tool_input": {"file_path": "/tmp/x"}})
        self.assertEqual(r.returncode, 0)
        self.assertEqual(self._decision(r.stdout), "allow")

    # ── pattern matching ─────────────────────────────────────────────────────

    def test_pattern_match_approves_matching_bash_command(self):
        self._write_state({"expires_at": int(time.time()) + 300, "pattern": "gh *", "notified": False})
        r = self._run_hook({"tool_name": "Bash", "tool_input": {"command": "gh repo list"}})
        self.assertEqual(r.returncode, 0)
        self.assertEqual(self._decision(r.stdout), "allow")

    def test_pattern_match_skips_non_matching_bash_command(self):
        self._write_state({"expires_at": int(time.time()) + 300, "pattern": "gh *", "notified": False})
        r = self._run_hook({"tool_name": "Bash", "tool_input": {"command": "ls -la"}})
        self.assertEqual(r.returncode, 0)
        self.assertEqual(r.stdout.strip(), "")

    def test_pattern_match_skips_non_bash_tool(self):
        self._write_state({"expires_at": int(time.time()) + 300, "pattern": "gh *", "notified": False})
        r = self._run_hook({"tool_name": "Read", "tool_input": {"file_path": "/tmp/x"}})
        self.assertEqual(r.returncode, 0)
        self.assertEqual(r.stdout.strip(), "")

    def test_glob_star_matches_any_suffix(self):
        self._write_state({"expires_at": int(time.time()) + 300, "pattern": "git *", "notified": False})
        r = self._run_hook({"tool_name": "Bash", "tool_input": {"command": "git status"}})
        self.assertEqual(self._decision(r.stdout), "allow")

    # ── session scoping ──────────────────────────────────────────────────────

    def test_matching_session_id_approves(self):
        self._write_state({
            "expires_at": int(time.time()) + 300, "pattern": "*", "notified": False,
            "session_id": "session-a",
        })
        r = self._run_hook({
            "tool_name": "Bash", "tool_input": {"command": "ls"}, "session_id": "session-a",
        })
        self.assertEqual(self._decision(r.stdout), "allow")

    def test_other_session_id_is_silent(self):
        self._write_state({
            "expires_at": int(time.time()) + 300, "pattern": "*", "notified": False,
            "session_id": "session-a",
        })
        r = self._run_hook({
            "tool_name": "Bash", "tool_input": {"command": "ls"}, "session_id": "session-b",
        })
        self.assertEqual(r.returncode, 0)
        self.assertEqual(r.stdout.strip(), "")

    def test_missing_session_id_in_state_approves_any_session(self):
        # Backward compat: state written before session scoping existed.
        self._write_state({"expires_at": int(time.time()) + 300, "pattern": "*", "notified": False})
        r = self._run_hook({
            "tool_name": "Bash", "tool_input": {"command": "ls"}, "session_id": "session-b",
        })
        self.assertEqual(self._decision(r.stdout), "allow")

    # ── expiry ───────────────────────────────────────────────────────────────

    def test_expired_window_notifies_once_then_silent(self):
        self._write_state({"expires_at": int(time.time()) - 1, "pattern": "*", "notified": False})

        r1 = self._run_hook({"tool_name": "Bash", "tool_input": {"command": "ls"}})
        self.assertEqual(r1.returncode, 0)
        out1 = json.loads(r1.stdout)
        self.assertIn("additionalContext", out1)
        self.assertIn("expired", out1["additionalContext"])

        # State must now have notified=True
        self.assertTrue(self._read_state()["notified"])

        # Second call — silent
        r2 = self._run_hook({"tool_name": "Bash", "tool_input": {"command": "ls"}})
        self.assertEqual(r2.returncode, 0)
        self.assertEqual(r2.stdout.strip(), "")

    def test_expired_already_notified_is_silent(self):
        self._write_state({"expires_at": int(time.time()) - 1, "pattern": "*", "notified": True})
        r = self._run_hook({"tool_name": "Bash", "tool_input": {"command": "ls"}})
        self.assertEqual(r.returncode, 0)
        self.assertEqual(r.stdout.strip(), "")

    # ── resilience ───────────────────────────────────────────────────────────

    def test_bad_json_stdin_exits_zero(self):
        r = subprocess.run(
            [sys.executable, HOOK],
            input="not json !!!",
            capture_output=True,
            text=True,
            env=self.env,
        )
        self.assertEqual(r.returncode, 0)

    def test_empty_stdin_exits_zero(self):
        r = subprocess.run(
            [sys.executable, HOOK],
            input="",
            capture_output=True,
            text=True,
            env=self.env,
        )
        self.assertEqual(r.returncode, 0)

    def test_corrupt_state_file_exits_zero(self):
        with open(self.state_file, "w") as f:
            f.write("{ not valid json")
        r = self._run_hook({"tool_name": "Bash", "tool_input": {"command": "ls"}})
        self.assertEqual(r.returncode, 0)


class TestCLI(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.env = {**os.environ, "KRONNY_STATE_DIR": self.tmp}
        self.state_file = os.path.join(self.tmp, "state.json")

    def _run_cli(self, *args):
        return subprocess.run(
            [sys.executable, CLI] + list(args),
            capture_output=True,
            text=True,
            env=self.env,
        )

    def _read_state(self):
        with open(self.state_file) as f:
            return json.load(f)

    # ── defaults ─────────────────────────────────────────────────────────────

    def test_no_args_defaults_5_minutes_wildcard(self):
        r = self._run_cli()
        self.assertEqual(r.returncode, 0)
        state = self._read_state()
        self.assertEqual(state["pattern"], "*")
        self.assertFalse(state["notified"])
        now = int(time.time())
        self.assertAlmostEqual(state["expires_at"], now + 300, delta=5)

    # ── session scoping ──────────────────────────────────────────────────────

    def test_session_id_from_env_is_stored(self):
        self.env["CLAUDE_CODE_SESSION_ID"] = "session-xyz"
        self._run_cli("5")
        self.assertEqual(self._read_state()["session_id"], "session-xyz")

    def test_missing_session_id_env_stores_empty_string(self):
        self.env.pop("CLAUDE_CODE_SESSION_ID", None)
        self._run_cli("5")
        self.assertEqual(self._read_state()["session_id"], "")

    # ── duration variants ────────────────────────────────────────────────────

    def test_explicit_minutes(self):
        r = self._run_cli("15")
        self.assertEqual(r.returncode, 0)
        now = int(time.time())
        self.assertAlmostEqual(self._read_state()["expires_at"], now + 900, delta=5)

    def test_minus_one_means_24h(self):
        r = self._run_cli("-1")
        self.assertEqual(r.returncode, 0)
        now = int(time.time())
        self.assertAlmostEqual(self._read_state()["expires_at"], now + 86400, delta=5)

    # ── pattern argument ─────────────────────────────────────────────────────

    def test_custom_pattern_stored(self):
        r = self._run_cli("15", "gh *")
        self.assertEqual(r.returncode, 0)
        self.assertEqual(self._read_state()["pattern"], "gh *")

    def test_wildcard_default_when_no_pattern(self):
        r = self._run_cli("10")
        self.assertEqual(r.returncode, 0)
        self.assertEqual(self._read_state()["pattern"], "*")

    # ── notified reset ───────────────────────────────────────────────────────

    def test_notified_always_false_on_new_window(self):
        # Pre-write a state with notified=True so we can confirm it's reset.
        with open(self.state_file, "w") as f:
            json.dump({"expires_at": 0, "pattern": "*", "notified": True}, f)
        self._run_cli("5")
        self.assertFalse(self._read_state()["notified"])

    # ── output messages ──────────────────────────────────────────────────────

    def test_output_mentions_all_tools_for_wildcard(self):
        r = self._run_cli("5")
        self.assertIn("ALL tools", r.stdout)

    def test_output_mentions_pattern_for_restricted(self):
        r = self._run_cli("5", "gh *")
        self.assertIn("gh *", r.stdout)

    # ── error cases ──────────────────────────────────────────────────────────

    def test_non_integer_minutes_fails(self):
        r = self._run_cli("notanumber")
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("Error", r.stderr)

    def test_zero_minutes_fails(self):
        r = self._run_cli("0")
        self.assertNotEqual(r.returncode, 0)

    def test_negative_minutes_other_than_minus1_fails(self):
        r = self._run_cli("-5")
        self.assertNotEqual(r.returncode, 0)

    # ── status ───────────────────────────────────────────────────────────────

    def test_status_no_state_file(self):
        r = self._run_cli("status")
        self.assertEqual(r.returncode, 0)
        self.assertIn("No active window", r.stdout)

    def test_status_active_window(self):
        with open(self.state_file, "w") as f:
            json.dump({"expires_at": int(time.time()) + 300, "pattern": "*", "notified": False}, f)
        r = self._run_cli("status")
        self.assertEqual(r.returncode, 0)
        self.assertIn("left", r.stdout)
        self.assertIn("ALL tools", r.stdout)

    def test_status_expired_window(self):
        with open(self.state_file, "w") as f:
            json.dump({"expires_at": int(time.time()) - 5, "pattern": "*", "notified": False}, f)
        r = self._run_cli("status")
        self.assertEqual(r.returncode, 0)
        self.assertIn("expired", r.stdout)

    def test_status_does_not_write_state(self):
        r = self._run_cli("status")
        self.assertEqual(r.returncode, 0)
        self.assertFalse(os.path.exists(self.state_file))

    def test_ttl_is_alias_for_status(self):
        with open(self.state_file, "w") as f:
            json.dump({"expires_at": int(time.time()) + 300, "pattern": "*", "notified": False}, f)
        r = self._run_cli("ttl")
        self.assertEqual(r.returncode, 0)
        self.assertIn("left", r.stdout)


if __name__ == "__main__":
    unittest.main(verbosity=2)

# Task board — đăng tin, xét duyệt, email

Orca Run `run_55b7db3023ae`. Không merge main/production. Rules không commit.

| ID | Worker | Mô tả / tiêu chí | Dependencies | Files | Status | Evidence | Commit |
|---|---|---|---|---|---|---|---|
| M-01 | Manager | Xác minh worktree, Orca và rules đọc được | Không | AGENTS.md, docs/agent-rules (local only) | APPROVED | Git worktree list; Orca runtime connected; cả hai worker phản hồi đã đọc rules | Không |
| task_aa952b34696b | Backend | Khảo sát status/API/auth/DB/email/test và đề xuất tối thiểu | M-01 | docs/backend-approval-survey.md tại worktree backend | APPROVED | worker_done succeeded, Manager đọc báo cáo; targeted baseline 9 tests pass | Không |
| task_b3a60e77a763 | Frontend | Khảo sát web/mobile/admin UI, API clients/test/build | M-01 | docs/frontend-approval-survey.md tại worktree frontend | APPROVED | worker_done succeeded, Manager đọc báo cáo; dependency chưa cài | Không |
| M-02 | Manager | Chốt contract từ khảo sát thực tế, chia sẻ đường dẫn tuyệt đối và xác nhận nhận | Hai survey | docs/approval-api-contract.md | APPROVED | FINAL v1.1; options API đọc, giữ route duyệt/status, assignment/admin, không resubmit; additive migration test-only | Chưa |
| task_46b8891e6125 | Backend | Validation, auth, transitions, audit, email sau commit/idempotency/retry, fake mail tests | M-02 | Java, migration, backend tests | READY_FOR_REVIEW | Worker_done succeeded;222 lượt/WAR pass, isolated test profile. Manager phát hiện R-07 cần fix trước chấp thuận | eee93cc; report1739cce |
| task_4ff06c1a245d | Backend | Fix R-07: Unicode whitespace reason + HTTP regression; không thay contract | Review BE | PropertyServiceImpl, integration test/report | IN_PROGRESS | Dispatch ctx_57508443f731; Java21 JShell chứng minh lỗi normalize | Chưa |
| task_2f70028c12a3 | Frontend | React/Flutter người đăng và Thymeleaf Staff, bắt buộc lý do, refetch, tests | M-02 | Web/mobile/template UI | FAILED | APK DNS storage.googleapis.com failed; retry stalled/cancelled. Manager độc lập xác nhận web27/lint/build và Flutter9/analyze122info pass | 265cef9; reportc9b6055 |
| M-QA | Manager | Review diff, unit/integration/build, kiểm tra email fake và tích hợp nhánh riêng | BE-IMPL, FE-IMPL | Báo cáo QA và nhánh tích hợp | TESTING | QA branch manager/approval-qa-20261023; FE cherry-pick8c5256b, checks frontend pass, chờ BE R-07 fix | 8c5256b |

## Công cụ

## Kết quả cuối sau kiểm chứng QA

Bảng dưới thay thế trạng thái checkpoint ở trên. Báo cáo chi tiết: `approval-manager-report.md`.

| Task | Trạng thái cuối | Evidence / commit |
|---|---|---|
| Backend implementation + task_4ff06c1a245d R-07 | APPROVED trong môi trường QA | eee93cc +523692f; Manager verify226 lượt/0 lỗi và WAR PASS; fake mail/security/H2/render |
| Frontend task_2f70028c12a3 | FAILED gate APK |265cef9; Manager web27/lint/build, Flutter9/analyze PASS; APK DNS dependency fail |
| M-QA | BLOCKED cho release toàn bộ | Tích hợp nhánh manager/approval-qa-20261023 đã kiểm; APK/nativeDB/browserE2E/SMTP thật chưa xác minh; chưa main/production |

R-01..R-07 đã được sửa và kiểm tra trên bản tích hợp. Không còn worker đang chạy task; terminal có sẵn được giữ nguyên khi release. Rules không nằm trong commit.

- `rg` không có trong PATH, dùng Git ls-files/PowerShell Select-String thay thế.
- JAVA_HOME mặc định D:/Java không trỏ JDK; Maven wrapper chạy được với JAVA_HOME process `D:/Java/jdk-21.0.12.1`, Maven 3.9.16/Java 21.
- Orca worker-start ban đầu trả `outcome_unknown/turn_start_unobserved`; kiểm tra thấy prompt pasted còn trong composer, đã submit Enter. Sau đó cả hai worker gửi status xác nhận rules. Không tạo duplicate worker.
- Chỉ copy file rules thiếu từ repo chính, không thay branch/commit. Rules untracked trong worker worktree; đã chỉ dẫn git add từng file cụ thể.

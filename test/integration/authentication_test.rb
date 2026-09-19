require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    SessionsController::RATE_LIMIT_STORE.clear
    RegistrationsController::RATE_LIMIT_STORE.clear
  end

  test "registration hashes password and cannot assign admin role" do
    assert_difference "User.count", 1 do
      post registration_path, params: { user: { name: "新しい会員", email: "NEW@example.com ", password: "new-password-123", password_confirmation: "new-password-123", admin: true } }
    end
    assert_redirected_to account_path
    user = User.find_by!(email: "new@example.com")
    assert_not user.admin?
    assert user.authenticate("new-password-123")
    assert_not_equal "new-password-123", user.password_digest
    follow_redirect!
    assert_select "h1", text: /新しい会員/
  end

  test "invalid registration has Japanese errors" do
    assert_no_difference "User.count" do
      post registration_path, params: { user: { name: "", email: "invalid", password: "short", password_confirmation: "different" } }
    end
    assert_response :unprocessable_entity
    assert_select ".form-errors", text: /パスワード/
  end

  test "login succeeds with normalized email and logout invalidates server session" do
    get account_path
    assert_redirected_to new_session_path
    post session_path, params: { email: " MEMBER@example.com ", password: "sample-password-123" }
    assert_redirected_to account_path
    assert_equal 1, users(:member).login_sessions.count
    get account_path
    assert_response :success
    delete session_path
    assert_equal 0, users(:member).login_sessions.count
    get account_path
    assert_redirected_to new_session_path
  end

  test "incorrect password cannot create session" do
    assert_no_difference "LoginSession.count" do
      post session_path, params: { email: users(:member).email, password: "wrong-password" }
    end
    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /メールアドレスまたはパスワード/
  end

  test "expired login session is rejected" do
    post session_path, params: { email: users(:member).email, password: "sample-password-123" }
    users(:member).login_sessions.update_all(expires_at: 1.minute.ago)
    get account_path
    assert_redirected_to new_session_path
  end

  test "login attempts are throttled" do
    10.times { post session_path, params: { email: "missing@example.com", password: "bad-password" } }
    post session_path, params: { email: "missing@example.com", password: "bad-password" }
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "[role=alert]", text: /試行回数/
  end
end

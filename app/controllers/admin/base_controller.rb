module Admin
  class BaseController < ApplicationController
    before_action :require_login
    before_action :require_admin
    before_action -> { response.headers["Cache-Control"] = "no-store" }

    private

    def require_admin
      render plain: "管理者権限が必要です。", status: :forbidden unless current_user&.admin?
    end
  end
end

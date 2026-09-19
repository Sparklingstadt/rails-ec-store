class AccountsController < ApplicationController
  before_action :require_login
  before_action -> { response.headers["Cache-Control"] = "no-store" }

  def show
  end
end

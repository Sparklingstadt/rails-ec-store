namespace :admin do
  desc "登録済みの会員に管理者権限を付与する (EMAIL=...)"
  task grant: :environment do
    email = ENV.fetch("EMAIL").strip.downcase
    user = User.find_by!(email: email)
    user.update!(admin: true)
    puts "#{user.email} に管理者権限を付与しました。"
  end
end

require File.expand_path('../../database.rb', __FILE__)
require 'csv'


def read_csv(csv_file)
  tickers = []
  CSV.foreach(csv_file, :headers => true, :header_converters => :symbol) do |row|
    tickers << Hash[row.headers.zip(row.fields)]
  end
  tickers
end


if(ENV['MODEL'] == 'User')
  users = read_csv(ARGV[0])
  users.each do |user_params|
    User.create(employee_id: user_params[:employee_id].to_i, first_name: user_params[:first_name], last_name: user_params[:last_name])
  end
end

if(ENV['MODEL'] == 'Book')
  book_data = read_csv(ARGV[0])
  book_data.each do |book_params|
    Book.create_from_google_api(book_params[:isbn], book_params[:copies].to_i)
  end
end


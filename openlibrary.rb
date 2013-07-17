require 'rubygems'
require 'bundler'
Bundler.require

require 'sinatra/content_for'
require 'sinatra/flash'
require './database'

set :environment, :production
set :logging, true
enable :sessions

get '/' do
  with_plain_layout :index
end

get '/issued-books' do
  @reservations = Reservation.all({:state => :issued.to_s})
  with_plain_layout :issued_books
end

get '/books' do
  @books = Book.all
  @reservations = Reservation.all(state: :issued.to_s).to_a
  with_plain_layout :books
end

get '/books/:isbn' do
  content_type :json
  load_book
  not_found and return if @book.nil?
  @reservation = Reservation.last(:book => @book)
  load_messages
  without_layout :book_info
end

post '/books/:isbn' do
  @book = Book.first(isbn: params[:isbn])
  @book.update(params[:book])
  without_layout(:donate_book)
end

get '/users' do
  @users = User.all(:order => [:id.desc])
  with_plain_layout :users
end

post '/user/create' do
  user = User.create(params[:user].merge(employee_id: params[:user]["employee_id"].to_i))
  if user.errors.empty?
    flash[:success] = "Successfully created user !!!"
  else
    flash[:error] = user.errors.full_messages.join(", ")
  end
  redirect '/users'
end

get '/barcode/:employee_id/create' do
  Process.detach(barcode_job)
  redirect '/barcode/success'
end

get '/barcode/success' do
  with_plain_layout :barcode_success
end

get '/donate' do
  with_plain_layout :donate
end

post '/donate' do
  @book_found = load_book
  @book = Book.create_from_google_api(params[:isbn]) unless @book_found
  without_layout(:donate_book)
end

post '/add_copies' do
  @book_found = load_book
  params[:copies_to_add].to_i.times{ @book.book_copies << BookCopy.create(book_id: @book.id) }
  without_layout(:donate_book)
end

get '/users/:employee_id/reserve/:isbn' do
  load_user_and_book
  load_messages
  not_found and return if @user.nil? || @book.nil?
  criteria = {:user => @user, :book => @book, :state => :issued.to_s}
  @reservation = get_reservation criteria
  @reservation.save
  send("send_#{@reservation.state}_msg")
  without_layout :reservation
end

def with_plain_layout template, options={}
  @menu_items = YAML::load(File.read(File.expand_path('config/menu.yml','.')))
  erb template, options.merge(:layout => :'layout/plain')
end

def without_layout template
  erb template
end

private

def barcode_job
  fork do
    load_user
    exec "sh ./create_barcode.sh #{params[:employee_id]}"
    email = Email.new(@user, nil)
    email.send_barcode_image
  end
end

def send_issued_msg
  email = Email.new(@user, @book)
  email.send_issued_msg
end

def send_returned_msg
  email = Email.new(@user, @book)
  email.send_returned_msg
end

def load_user_and_book
  load_user
  load_book
end

def load_user
  @user = User.first(:employee_id => params[:employee_id].to_i)
end

def load_book
  @book = Book.first(:isbn => params[:isbn])
end

def load_messages
  @messages = YAML::load(File.read(File.expand_path('config/en.yml','.')))
end

def get_reservation criteria
  reservation = Reservation.first(criteria)
  reservation.forward! unless reservation.nil?
  reservation ||= Reservation.create(criteria)
  return reservation
end

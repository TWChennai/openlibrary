class Book
  include DataMapper::Resource

  property :id, Serial, :required => true
  property :isbn, String, :index => true, :required => true, :length => 255
  property :title, String, :required => true, :length => 255
  property :author, String, :required => true, :length => 255
  property :photo_remote_url, String, :length => 255
  has n, :book_copies
  has n, :reservation

  def self.create_from_google_api(isbn, copies=1)
    params = details_from_google(isbn) || {:isbn => isbn, :title => 'N/A', :author => 'N/A'}
    Book.create(params).tap do |b|
      copies.times{ b.book_copies << BookCopy.create(book_id: b.id) }
    end
  end

  def self.details_from_google(isbn)
    items = "https://www.googleapis.com/books/v1/volumes?q=isbn:#{isbn}&fields=items(volumeInfo(authors,description,imageLinks,industryIdentifiers,title))".to_uri.get.deserialise["items"]
    return nil if items.nil?
    response = items[0]["volumeInfo"]
    {}.tap do |p|
      p[:isbn] = isbn
      p[:title] = response["title"]
      p[:author] = response["authors"] ? response["authors"].join(", ") : 'N/A'
      p[:photo_remote_url] = response["imageLinks"]["thumbnail"] if response["imageLinks"]
    end
  end
end

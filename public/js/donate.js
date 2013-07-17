var DonateBookView = Backbone.View.extend({
  initialize: function(){
    this.setElement($(".donate"));
  },

  events: {
    "change input.barcode": "saveBook",
    "click input[value=Add]": "addCopies",
    "submit form": "updateBookData"
  },

  saveBook: function(event){
    var isbn = $(event.target); 
    var isbnRegex = /^(\w{13}|\w{10})$/;
    if (!isbnRegex.test(isbn.val())){
      isbn.val("");
      return;
    }
    var postReq = $.post("/donate", {isbn: isbn.val()}, $.proxy(this.updateBookView, this))
  },

  addCopies: function(){
    var params = {isbn: $("input[name=isbn]").val(), copies_to_add: $("input[type=number]").val()};
    $.post("/add_copies", params, $.proxy(this.updateBookView, this));
  },

  updateBookData: function(event){
    event.preventDefault();
    console.log($(event.target))
    var formToPost = $(event.target)
    $.post(formToPost.attr("action"), formToPost.serialize(), $.proxy(this.updateBookView, this));
  },

  updateBookView: function(responseText) {
    $(this.el).find(".book-info").replaceWith(responseText);
    $('body').removeClass('modal-open');
    $('.modal-backdrop').remove();
  } 
});

$(function() { new DonateBookView(); });

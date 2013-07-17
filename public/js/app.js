$(document).ajaxSend(function(){$.blockUI();});
$(document).ajaxStop(function(){$.unblockUI()});
$(document).ajaxError(function(){
  $.unblockUI();
  window.alert("An error occurred...");
});

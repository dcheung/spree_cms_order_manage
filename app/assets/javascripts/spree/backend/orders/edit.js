$(document).ready(function () {
  'use strict';

  $('[data-hook="add_product_name"]').find('.variant_autocomplete').variantAutocomplete();

});

jQuery(function($) {
  // Make select beautiful
  $('select.select3').select2({
    allowClear: true,
    dropdownAutoWidth: true
  });
});

$(document).on("click", ".expand-trigger", function()
{
  var objectContent = $(this).parent().parent().find(".content");
  var icon = $(this).find(".icon");

  $(icon).toggleClass("expand");

  objectContent.stop().slideToggle();

});

$(document).on("click", ".dow-block .title .status.show", function()
{ 
  //console.log("edit");
  toggleEdit(this);
});

$(document).on("click", ".dow-block .title .status.edit", function()
{

});

//Save button
$(document).on("click", ".dow-block .title .button.save", function()
{
  var orderId = $(".order-info").attr("data-order-id");
  var status = $(this).parent().find("select.select3").val();
  var dateDelivery = $(this).parent().parent().find(".date-delivery").text();

  // console.log($(this).parent().find("select.select3"));
  // console.log("STATUS: " + status);

  UpdateLineItemStatus(orderId, status, dateDelivery, $(this));

});

$(document).on("click", ".dow-block .title .button.cancel", function()
{
  toggleEdit(this);
});


function toggleEdit(that)
{
  $(that).parent().find(".status.edit").toggle();

  if($(that).parent().find(".status.edit").is(":visible"))
  {
    var status = $(that).parent().find(".status.show span").text().trim();
    console.log("STATUS: " + status);
    $(that).parent().find("select.select3").select2("val", status);
  }

  $(that).parent().find(".status.show").toggle();
  $(that).parent().find(".button.save").toggle();
  $(that).parent().find(".button.cancel").toggle();
}

//=====================
function UpdateLineItemStatus(orderId, status, dateDelivery, that)
{
  var apiUrl = Spree.routes.orders_api = Spree.pathFor('api/orders') + "/" + orderId + "/line_items_status";

  $.ajax({
    type: "post",
    url: apiUrl,
    data:
    {
      line_item : {
        status: status,
        delivery_date: dateDelivery
      },
      token: Spree.api_key
    },
    success: function(r)
    {
      show_flash("success", "Update line item status successfully!");
      toggleEdit(that);

      $(that).parent().find(".status.show span").text(status);
    },
    error: function(e)
    {
      show_flash("error", "Error!");
    }
  });
}

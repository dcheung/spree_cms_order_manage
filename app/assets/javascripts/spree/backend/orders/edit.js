$(document).ready(function () {
  'use strict';

  $('[data-hook="add_product_name"]').find('.variant_autocomplete').variantAutocomplete();
});


$(document).on("click", ".dow-block", function()
{
  var objectContent = $(this).find(".content");
  var icon = $(this).find(".icon");

  $(icon).toggleClass("expand");

  objectContent.slideToggle();

});
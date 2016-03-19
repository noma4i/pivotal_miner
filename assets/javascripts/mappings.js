$(document).ready(function ($) {
  $('#tracker_project_id').on('change', function() {
    var tracker_project_id = $(this).val();
    $.ajax('/mappings/update_labels', {
      success: function(response) {
        $('#mapping_label option').remove();
        $('#mapping_label').append("<option value='sync_all_labels'>-- ALL LABELS --</option>");
        $.each(response, function(index, label){
          $('#mapping_label').append("<option value=" + label +">"+ label + "</option>");
        });
      },
      data: { 'tracker_project_id': tracker_project_id }
    });
  });
  $('#tracker_project_id').change();

  $('#pivotal_user_mapping').on('change', function() {
    var user_id = $(this).val();
    var pivotal_id = $(this).parents('td').data('pivotal-id');
    $.ajax('/mappings/update_user', {
      success: function(response) {
        alert('User mapped!');
      },
      data: { 'user_id': user_id, 'pivotal_id': pivotal_id }
    });
  });
});
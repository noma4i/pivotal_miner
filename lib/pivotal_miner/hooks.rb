module Tracmine
  class Hooks < Redmine::Hook::ViewListener
    def view_issues_show_description_bottom(context)
      controller = context[:controller]

      controller.render_to_string({:partial => 'hooks/pivotal_miner/view_issues_show_description_bottom', :locals => context})
    end

    def view_layouts_base_html_head(context)
      stylesheet_link_tag('pivotal_miner.css', plugin: 'pivotal_miner')
    end
  end
end

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

	def select_tag_for_filter(nvpairs, params)
	  _url = ( url_for :overwrite_params => { }).split('?')[0]
	  _html = %{<span class="pull-left filter-label">Filter: </span> }
	  _html << %{<select name="show" class="filter-select" }
	  _html << %{onchange="window.location='#{_url}' + '?show=' + this.value"> }
	  nvpairs.each do |pair|
    	_html << %{<option value="#{h(pair[:scope])}" }
    	if params[:show] == pair[:scope] || ((params[:show].nil? || params[:show].empty?) && pair[:scope] == "all")
    	  _html << %{ selected="selected" }
    	end
    	_html << %{>#{pair[:label]} }
    	_html << %{</option>}
	  end
	  _html << %{</select>}
	  raw(_html)
	end

	def select_match_scope(nvpairs, params)
	  _url = ( url_for :overwrite_params => { }).split('?')[0]
	  _html = %{<span class="pull-left filter-label">Matching Scope: </span> }
	  _html << %{<select name="match_scope" class="filter-select" }
	  _html << %{onchange="window.location='#{_url}' + '?match_scope=' + this.value"> }
	  nvpairs.each do |pair|
    	_html << %{<option value="#{h(pair[:scope])}" }
    	if params[:match_scope] == pair[:scope] || ((params[:match_scope].nil? || params[:match_scope].empty?) && pair[:scope] == "job")
    	  _html << %{ selected="selected" }
    	end
    	_html << %{>#{pair[:label]} }
    	_html << %{</option>}
	  end
	  _html << %{</select>}
	  raw(_html)
	end

	def set_focus(element_id)
		javascript_tag(" $elem = $(\"#{element_id}\"); if (null !== $elem && $elem.length > 0){$elem.focus()}")
	end

	def format_job_details(job)
		begin
			info = Marshal.load(job.args.to_s)

			ttip = raw("<div class='task_args_formatted'>")
			info.each_pair do |k,v|
				ttip << raw("<div class='task_args_var'>") + h(truncate(k.to_s, :length => 20)) + raw(": </div> ")
				ttip << raw("<div class='task_args_val'>") + h(truncate((v.to_s), :length => 20)) + raw("&nbsp;</div>")
			end
			ttip << raw("</div>\n")
			outp = raw("<span class='xpopover' rel='popover' data-title=\"#{job.task.capitalize} Task ##{job.id}\" data-content=\"#{ttip}\">#{h job.task.capitalize}</span>")
			outp
		rescue ::Exception => e
			job.status.to_s.capitalize
		end
	end

	def format_call_type_details(call)
			ttip = raw("<div class='task_args_formatted'>")


			ttip << raw("<div class='task_args_var'>Call Time:</div> ")
			ttip << raw("<div class='task_args_val'>") + h(call.created_at.strftime("%Y-%m-%d %H:%M:%S %Z")) + raw("&nbsp;</div>")

			ttip << raw("<div class='task_args_var'>CallerID:</div> ")
			ttip << raw("<div class='task_args_val'>") + h(call.caller_id) + raw("&nbsp;</div>")

			ttip << raw("<div class='task_args_var'>Provider:</div> ")
			ttip << raw("<div class='task_args_val'>") + h(call.provider.name) + raw("&nbsp;</div>")


			ttip << raw("<div class='task_args_var'>Audio:</div> ")
			ttip << raw("<div class='task_args_val'>") + h(call.audio_length.to_s) + raw("&nbsp;</div>")


			ttip << raw("<div class='task_args_var'>Ring:</div> ")
			ttip << raw("<div class='task_args_val'>") + h(call.ring_length.to_s) + raw("&nbsp;</div>")

			ttip << raw("</div>\n")
			outp = raw("<span class='xpopover' rel='popover' data-title=\"#{h call.number.to_s }\" data-content=\"#{ttip}\"><strong>#{h call.line_type.upcase }</strong></span>")
			outp
	end


	def format_job_status(job)
		case job.status
		when 'error'
			ttip = h(job.error.to_s)
			outp = raw("<span class='xpopover' rel='popover' data-title=\"Task Details\" data-content=\"#{ttip}\">#{h job.status.capitalize}</span>")
			outp
		else
			job.status.to_s.capitalize
		end
	end

	#
	# Includes any javascripts specific to this view. The hosts/show view
	# will automatically include any javascripts at public/javascripts/hosts/show.js.
	#
	# @return [void]
	def include_view_javascript
		#
		# Sprockets treats index.js as special, so the js for the index action must be called _index.js instead.
		# http://guides.rubyonrails.org/asset_pipeline.html#using-index-files
		#

		controller_action_name = controller.action_name

		if controller_action_name == 'index'
			safe_action_name = '_index'
		else
			safe_action_name = controller_action_name
		end

		include_view_javascript_named(safe_action_name)
	end

	# Includes the named javascript for this controller if it exists.
	#
	# @return [void]
	def include_view_javascript_named(name)

		controller_path = controller.controller_path
		extensions = ['.coffee', '.js.coffee']
		javascript_controller_pathname = Rails.root.join('app', 'assets', 'javascripts', controller_path)
		pathnames = extensions.collect { |extension|
			javascript_controller_pathname.join("#{name}#{extension}")
		}

		if pathnames.any?(&:exist?)
			path = File.join(controller_path, name)
			content_for(:view_javascript) do
				javascript_include_tag path
			end
		end
	end



  #
  # Generate pagination links
  #
  # Parameters:
  #   :name:: the kind of the items we're paginating
  #   :items:: the collection of items currently on the page
  #   :count:: total count of items to paginate
  #   :offset:: offset from the beginning where +items+ starts within the total
  #   :page:: current page
  #   :num_pages:: total number of pages
  #
  def page_links(opts={})
    link_method = opts[:link_method]
    if not link_method or not respond_to? link_method
      raise RuntimeError.new("Need a method for generating links")
    end
    name      = opts[:name] || ""
    items     = opts[:items] || []
    count     = opts[:count] || 0
    offset    = opts[:offset] || 0
    page      = opts[:page] || 1
    num_pages = opts[:num_pages] || 1

    page_list = ""
    1.upto(num_pages) do |p|
      if p == page
        page_list << content_tag(:span, :class=>"current") { h page }
      else
        page_list << self.send(link_method, p, { :page => p })
      end
    end
    content_tag(:div, :id => "page_links") do
      content_tag(:span, :class => "index") do
        if items.size > 0
          "#{offset + 1}-#{offset + items.size} of #{h pluralize(count, name)}" + "&nbsp;"*3
        else
          h(name.pluralize)
        end.html_safe
      end +
        if num_pages > 1
          self.send(link_method, '', { :page => 0 }, { :class => 'start' }) +
            self.send(link_method, '', { :page => page-1 }, {:class => 'prev' }) +
            page_list +
            self.send(link_method, '', { :page => [page+1,num_pages].min }, { :class => 'next' }) +
            self.send(link_method, '', { :page => num_pages }, { :class => 'end' })
        else
          ""
        end
    end
  end

	def submit_checkboxes_to(name, path, html={})
		if html[:confirm]
			confirm = html.delete(:confirm)
			link_to(name, "#", html.merge({:onclick => "if(confirm('#{h confirm}')){ submit_checkboxes_to('#{path}','#{form_authenticity_token}')}else{return false;}" }))
		else
			link_to(name, "#", html.merge({:onclick => "submit_checkboxes_to('#{path}','#{form_authenticity_token}')" }))
		end
	end

	# Scrub out data that can break the JSON parser
	#
	# data - The String json to be scrubbed.
	#
	# Returns the String json with invalid data removed.
	def json_data_scrub(data)
		data.to_s.gsub(/[\x00-\x1f]/){ |x| "\\x%.2x" % x.unpack("C*")[0] }
	end

	# Returns the properly escaped sEcho parameter that DataTables expects.
	def echo_data_tables
		h(params[:sEcho]).to_json.html_safe
	end

	# Generate the markup for the call's row checkbox.
	# Returns the String markup html, escaped for json.
	def call_checkbox_tag(call)
		check_box_tag("result_ids[]", call.id, false, :id => nil).to_json.html_safe
	end

	def call_number_html(call)
		json_data_scrub(h(call.number)).to_json.html_safe
	end

	def call_caller_id_html(call)
		json_data_scrub(h(call.caller_id)).to_json.html_safe
	end

	def call_provider_html(call)
		json_data_scrub(h(call.provider.name)).to_json.html_safe
	end

	def call_answered_html(call)
		json_data_scrub(h(call.answered ? "Yes" : "No")).to_json.html_safe
	end

	def call_busy_html(call)
		json_data_scrub(h(call.busy ? "Yes" : "No")).to_json.html_safe
	end

	def call_audio_length_html(call)
		json_data_scrub(h(call.audio_length.to_s)).to_json.html_safe
	end

	def call_ring_length_html(call)
		json_data_scrub(h(call.ring_lenght.to_s)).to_json.html_safe
	end


end

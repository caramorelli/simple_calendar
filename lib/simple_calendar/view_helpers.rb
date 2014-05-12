module SimpleCalendar
  module ViewHelpers
    def month_calendar(param_name=:start_date, options={}, &block)
      start_date = (params[param_name] || Time.zone.now).to_date

      options.reverse_merge!(
        prev_link: ->(range) { link_to raw("&laquo;"), param_name => range.first - 1.day },
        header: ->{ content_tag :span, "#{I18n.t("date.month_names")[start_date.month]} #{start_date.year}", class: "calendar-header" },
        next_link: ->(range) { link_to raw("&raquo;"), param_name => range.last + 1.day },
      )
      render_calendar month_range(start_date), options, &block
    end

    def week_calendar(param_name=:start_date, options={}, &block)
      start_date = (params[param_name] || Time.zone.now).to_date
      number_of_weeks = options.fetch(:number_of_weeks, 1)

      options.reverse_merge!(
        prev_link: ->(range) { link_to raw("&laquo;"), param_name => range.first - 1.day },
        header: false,
        next_link: ->(range) { link_to raw("&raquo;"), param_name => range.last + 1.day },
      )
      render_calendar week_range(start_date, number_of_weeks), options, &block
    end

    def calendar(param_name=:start_date, options={}, &block)
      start_date = (params[param_name] || Time.zone.now).to_date
      number_of_days_to_advance = options.fetch(:number_of_days, 4) - 1

      options.reverse_merge!(
        prev_link: ->(range) { link_to raw("&laquo;"), param_name => range.first - 1.day },
        header: false,
        next_link: ->(range) { link_to raw("&raquo;"), param_name => range.last + 1.day },
      )
      render_calendar calendar_range(start_date, number_of_days_to_advance), options, &block
    end

    def month_range(start_date)
      start_date.beginning_of_month.beginning_of_week.to_date..start_date.end_of_month.end_of_week.to_date
    end

    def week_range(start_date, number_of_weeks)
      number_of_days_to_advance = (number_of_weeks * 7) - 1
      starting_day              = start_date.beginning_of_week.to_date
      ending_day                = starting_day + number_of_days_to_advance.days
      starting_day..ending_day
    end

    def calendar_range(start_date, number_of_days_to_advance)
      start_date..(start_date + number_of_days_to_advance.days)
    end

    def render_calendar(range, options, &block)
      raise 'SimpleCalendar requires a block' unless block_given?

      @block   = block
      @options = options.reverse_merge default_options

      capture do
        concat render_header(range)
        concat render_table(range)
      end
    end

    def render_header(range)
      capture do
        content_tag :div do
          concat get_options(@options[:prev_link], range)
          concat get_options(@options[:header])
          concat get_options(@options[:next_link], range)
        end
      end
    end

    def render_table(range)
      content_tag(:table, get_options(@options[:table])) do
        content_tag(:tbody) do
          render_weeks(range)
        end
      end
    end


    def render_weeks(range)
      weeks = []
      range.each_slice(7) do |week|
        weeks << content_tag(:tr, get_options(@options[:tr], week)) do
          render_week(week)
        end
      end
      safe_join weeks
    end

    def render_week(week)
      results = week.map do |day|
        content_tag :td, get_options(@options[:td], day) do
          @block.call(day)
        end
      end
      safe_join results
    end

    def get_options(options, *params)
      case options
      when Hash
        options
      when String
        send(options, *params)
      when Symbol
        send(options, *params)
      else
        options.call(*params) if options.respond_to? :call
      end
    end

    def default_options
      { table: {}, tr: {}, td: {}, }
    end
  end
end

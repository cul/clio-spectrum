module Clicktale
  module Controller

    def self.included(base)
      base.class_eval do
        @@clicktale_options = {}
        # around_filter :clicktaleize
        after_filter :clicktaleize
        helper_method :clicktale_enabled?
        helper_method :clicktale_config
        helper_method :clicktale_path
        helper_method :clicktale_url
      end
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      def clicktale(opts = {})
        @@clicktale_options = opts
      end
    end

    def clicktale(opts = {})
      @clicktale_options = opts
    end

    def clicktaleize
      # res = yield
      if clicktale_enabled? && response.body.present?
        body = response.body

        # near the top, 
        top_regexp = clicktale_config[:insert_after] || /(\<body[^\>]*\>)/
        body.sub!(top_regexp) { |match| match + "\n" + clicktale_config[:top] }

        bottom_regexp = clicktale_config[:insert_before] || /(\<\/body\>)/
        body.sub!(bottom_regexp) { |match| "\n\n" + clicktale_bottom + "\n\n" + match }

        response.body = body
        cache_path = "/clicktale/clicktale_#{clicktale_cache_token}"
        cache_page(nil, cache_path)
      end
      # res
    end

    def clicktale_enabled?
      @clicktale_enabled ||= clicktale_config[:enabled] &&
        clicktale_config[:clicktale_project_code] &&
        request.format.try(:html?) &&
        request.get? &&
        !(request.path =~ /clicktale.*\.html$/) &&
        cookie_enabled? &&
        regexp_enabled?
    end

    def clicktale_config
      @clicktale_config ||= Clicktale::CONFIG.merge(@@clicktale_options || {}).merge(@clicktale_options || {})
    end

    protected

    def clicktale_bottom
      clicktale_config[:bottom].
        gsub(/CLICKTALE_FETCH_FROM_URL/, clicktale_url).
        gsub(/CLICKTALE_PROJECT_CODE/, clicktale_config[:clicktale_project_code] || 'none')
    end

    def regexp_enabled?
      clicktale_config[:do_not_record].present? ? !(response.body =~ clicktale_config[:do_not_record]) : true
    end

    def cookie_enabled?
      if clicktale_config[:do_not_process_cookie_name].present?
        cookies[clicktale_config[:do_not_process_cookie_name]] != clicktale_config[:do_not_process_cookie_value]
      else
        true
      end
    end

    def clicktale_cache_token(extra = "")
      @clicktale_cache_token ||= Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join + extra)
    end

    def clicktale_path
      @clicktale_path ||= "/clicktale/clicktale_#{clicktale_cache_token}.html"
    end

    def clicktale_url
      @clicktale_url ||= "#{request.protocol}#{request.host_with_port}#{clicktale_path}"
    end
  end
end

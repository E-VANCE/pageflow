module Pageflow
  # Options to be defined in the pageflow initializer of the main app.
  class Configuration
    # Default options for paperclip attachments which are supposed to
    # use filesystem storage.
    attr_accessor :paperclip_filesystem_default_options

    # Default options for paperclip attachments which are supposed to use
    # s3 storage.
    attr_accessor :paperclip_s3_default_options

    # String to interpolate into paths of files generated by paperclip
    # preprocessors. This allows to refresh cdn caches after
    # reprocessing attachments.
    attr_accessor :paperclip_attachments_version

    # Path to the location in the filesystem where attachments shall
    # be stored. The value of this option is available via the
    # pageflow_filesystem_root paperclip interpolation.
    attr_accessor :paperclip_filesystem_root

    # Refer to the pageflow initializer template for a list of
    # supported options.
    attr_accessor :zencoder_options

    # A constraint used by the pageflow engine to restrict access to
    # the editor related HTTP end points. This can be used to ensure
    # the editor is only accessable via a certain host when different
    # CNAMES are used to access the public end points of pageflow.
    attr_accessor :editor_route_constraint

    # The email address to use as from header in invitation mails to
    # new users
    attr_accessor :mailer_sender

    # Subscribe to hooks in order to be notified of events. Any object
    # with a call method can be a subscriber
    #
    # Example:
    #
    #     config.hooks.subscribe(:submit_file, -> { do_something })
    #
    attr_reader :hooks

    # Limit the use of certain resources. Any object implementing the
    # interface of Pageflow::Quota can be registered.
    #
    # Example:
    #
    #     config.quotas.register(:users, UserQuota)
    #
    attr_accessor :quotas

    # Additional themes can be registered to use custom css.
    #
    # Example:
    #
    #     config.themes.register(:custom)
    #
    # @return [Themes]
    attr_reader :themes

    # List of {FileType} instances provided by page types.
    # @return [FileTypes]
    attr_reader :file_types

    # Used to register new types of widgets to be displayed in entries.
    # @return [WidgetTypes]
    attr_reader :widget_types

    # Used to add new sections to the help dialog displayed in the
    # editor.
    #
    # @exmaple
    #
    #   config.help_entries.register('pageflow.rainbow.help_entries.colors', priority: 11)
    #   config.help_entries.register('pageflow.rainbow.help_entries.colors.blue',
    #                                parent: 'pageflow.rainbow.help_entries.colors')
    #
    # @since 0.7
    # @return [HelpEntries]
    attr_reader :help_entries

    # Paperclip style definitions of thumbnails used by Pageflow.
    # @return Hash
    attr_accessor :thumbnail_styles

    # Names of Paperclip styles that shall be rendered into entry
    # specific stylesheets.
    # @return Array<Symbol>
    attr_accessor :css_rendered_thumbnail_styles

    # Either a lambda or an object with a `match?` method, to restrict
    # access to the editor routes defined by Pageflow.
    #
    # This can be used if published entries shall be available under
    # different CNAMES but the admin and the editor shall only be
    # accessible via one official url.
    attr_accessor :editor_routing_constraint

    # Either a lambda or an object with a `call` method taking two
    # parameters: An `ActiveRecord` scope of {Pageflow::Theming} records
    # and an {ActionDispatch::Request} object. Has to return the scope
    # in which to find themings.
    #
    # Defaults to {CnameThemingRequestScope} which finds themings
    # based on the request subdomain. Can be used to alter the logic
    # of finding a theming whose home_url to redirect to when visiting
    # the public root path.
    #
    # Example:
    #
    #     config.theming_request_scope = lambda do |themings, request|
    #       themings.where(id: Pageflow::Account.find_by_name!(request.subdomain).default_theming_id)
    #     end
    attr_accessor :theming_request_scope

    # Either a lambda or an object with a `call` method taking two
    # parameters: An `ActiveRecord` scope of `Pageflow::Entry` records
    # and an `ActionDispatch::Request` object. Has to return the scope
    # in which to find entries.
    #
    # Used by all public actions that display entries to restrict the
    # available entries by hostname or other request attributes.
    #
    # Use {#public_entry_url_options} to make sure urls of published
    # entries conform twith the restrictions.
    #
    # Example:
    #
    #     # Only make entries of one account available under <account.name>.example.com
    #     config.public_entry_request_scope = lambda do |entries, request|
    #       entries.includes(:account).where(pageflow_accounts: {name: request.subdomain})
    #     end
    attr_accessor :public_entry_request_scope

    # Either a lambda or an object with a `call` method taking a
    # {Theming} as paramater and returing a hash of options used to
    # construct the url of a published entry.
    #
    # Can be used to change the host of the url under which entries
    # are available.
    #
    # Example:
    #
    #     config.public_entry_url_options = lambda do |theming|
    #       {host: "#{theming.account.name}.example.com"}
    #     end
    attr_accessor :public_entry_url_options

    # Submit video/audio encoding jobs only after the user has
    # explicitly confirmed in the editor. Defaults to false.
    attr_accessor :confirm_encoding_jobs

    # Used by Pageflow extensions to provide new tabs to be displayed
    # in the admin.
    #
    # @example
    #
    #     config.admin_resource_tabs.register(:entry, Admin::CustomTab)
    #
    # @return [Admin::TabsRegistry]
    attr_reader :admin_resource_tabs

    # Array of locales which can be chosen as interface language by a
    # user or for an entry. Defaults to `I18n.available_locales`.
    # @since 0.7
    attr_accessor :available_locales

    def initialize
      @paperclip_filesystem_default_options = {}
      @paperclip_s3_default_options = {}

      @zencoder_options = {}

      @mailer_sender = 'pageflow@example.com'

      @hooks = Hooks.new
      @quotas = Quotas.new
      @themes = Themes.new
      @file_types = FileTypes.new(page_types)
      @widget_types = WidgetTypes.new
      @help_entries = HelpEntries.new

      @thumbnail_styles = {}
      @css_rendered_thumbnail_styles = Pageflow::PagesHelper::CSS_RENDERED_THUMBNAIL_STYLES

      @theming_request_scope = CnameThemingRequestScope.new
      @public_entry_request_scope = lambda { |entries, request| entries }
      @public_entry_url_options = Pageflow::ThemingsHelper::DEFAULT_PUBLIC_ENTRY_OPTIONS

      @confirm_encoding_jobs = false

      @admin_resource_tabs = Pageflow::Admin::Tabs.new

      @available_locales = Engine.config.i18n.available_locales
    end

    # Make a page type available for use in the system.
    def register_page_type(page_type)
      page_types << page_type

      @page_types_by_name ||= {}
      @page_types_by_name[page_type.name] = page_type
    end

    def lookup_page_type(name)
      @page_types_by_name.fetch(name)
    end

    def page_types
      @page_types ||= []
    end

    def page_type_names
      page_types.map(&:name)
    end

    def revision_components
      page_types.map(&:revision_components).flatten.uniq
    end

    # @api private
    def theming_url_options(theming)
      options = public_entry_url_options
      options.respond_to?(:call) ? options.call(theming) : options
    end
  end
end

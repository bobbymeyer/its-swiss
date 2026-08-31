module ItsSwiss
  # The specimen is documentation and a regression fixture, not a page an
  # application serves. Refused unless the configuration has asked for it —
  # the installer mounts the engine inside `if Rails.env.development?`, and
  # this is the second lock, because a route is a line in a file someone can
  # move and this page names every component the library has.
  class SpecimenController < ActionController::Base
    layout "its_swiss/shell"

    before_action :refuse_unless_asked_for

    def show
      @sizes = (1..5).map { |step| "--size-#{step}" }
      @values = (0..5).map { |step| "--value-#{step}" }
    end

    private
      def refuse_unless_asked_for
        return if ItsSwiss.config.specimen?

        raise ActionController::RoutingError, "the its-swiss specimen is not enabled in #{Rails.env}"
      end
  end
end

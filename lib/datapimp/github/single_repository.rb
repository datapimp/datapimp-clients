module Datapimp
  module Github
    class SingleRepository < Request

      def endpoint
        "repos/#{ org }/#{ repo }"
      end
    end
  end
end
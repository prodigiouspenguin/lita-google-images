require "lita"

module Lita
  module Handlers
    class GoogleImages < Handler
      URL = "https://ajax.googleapis.com/ajax/services/search/images"

      route(/(?:image|img)(?:\s+me)? (.+)/, :fetch, command: true, help: {
        "image QUERY" => "Displays a random image from Google Images matching the query."
      })

      def self.default_config(handler_config)
        handler_config.safe_search = :active
      end

      def fetch(response)
        query = response.matches[0][0]
        
        if query == "nerd"
          response.reply "https://s3.amazonaws.com/uploads.hipchat.com/100435/736860/Ws7YsUi16ZqVIdO/10494679_274598749390335_7574233383180516120_n.jpg"
        else
          http_response = http.get(
            URL,
            v: "1.0",
            q: query,
            safe: safe_value,
            rsz: 8
          )

          data = MultiJson.load(http_response.body)

         if data["responseStatus"] == 200
            choice = data["responseData"]["results"].sample
            if choice
              response.reply ensure_extension(choice["unescapedUrl"])
            else
              response.reply %{No images found for "#{query}".}
            end
          else
            reason = data["responseDetails"] || "unknown error"
            Lita.logger.warn(
              "Couldn't get image from Google: #{reason}"
            )
          end
        end
      end

      private

      def ensure_extension(url)
        if [".gif", ".jpg", ".jpeg", ".png"].any? { |ext| url.end_with?(ext) }
          url
        else
          "#{url}#.png"
        end
      end

      def safe_value
        safe = Lita.config.handlers.google_images.safe_search || "active"
        safe = safe.to_s.downcase
        safe = "active" unless ["active", "moderate", "off"].include?(safe)
        safe
      end
    end

    Lita.register_handler(GoogleImages)
  end
end

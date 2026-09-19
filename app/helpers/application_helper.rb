module ApplicationHelper
  def yen(amount)
    number_to_currency(amount, unit: "¥", precision: 0, format: "%u%n", delimiter: ",")
  end

  def icon(name, **options)
    paths = {
      "search" => [ "M21 21l-5-5", "M18 10a8 8 0 1 1-16 0 8 8 0 0 1 16 0" ],
      "bag" => [ "M5 7h14l1 14H4L5 7Z", "M9 8V6a3 3 0 0 1 6 0v2" ],
      "heart" => [ "M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1.1-1.1a5.5 5.5 0 0 0-7.8 7.8L12 21l8.8-8.6a5.5 5.5 0 0 0 0-7.8Z" ],
      "arrow" => [ "M4 12h16", "m14 6 6 6-6 6" ],
      "check" => [ "m5 12 4 4L19 6" ],
      "box" => [ "m12 3 9 5-9 5-9-5 9-5Z", "M3 8v10l9 5 9-5V8", "M12 13v10", "m7 5 9 5" ],
      "truck" => [ "M1 4h13v13H1V4Z", "M14 9h4l4 4v4h-8", "M8 18a2 2 0 1 1-4 0 2 2 0 0 1 4 0", "M20 18a2 2 0 1 1-4 0 2 2 0 0 1 4 0" ],
      "leaf" => [ "M20 3C8 1 1 8 5 16s17 4 15-13Z", "M3 21 15 9" ],
      "close" => [ "m6 6 12 12", "M6 18 18 6" ],
      "minus" => [ "M5 12h14" ], "plus" => [ "M5 12h14", "M12 5v14" ]
    }
    tag.svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": 1.4, "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": true, class: "icon", **options) do
      safe_join(paths.fetch(name).map { |path| tag.path(d: path) })
    end
  end
end

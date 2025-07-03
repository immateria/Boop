#
# {
#     "api": 1,
#     "name": "Ruby Downcase",
#     "description": "Converts your text to lowercase using Ruby.",
#     "author": "Codex",
#     "icon": "type",
#     "tags": "downcase,ruby"
# }
#

def main(state)
  if state.text
    state.text = state.text.downcase
  end
end

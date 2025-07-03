"""
{
    "api": 1,
    "name": "Python Upcase",
    "description": "Converts your text to uppercase using Python.",
    "author": "Codex",
    "icon": "type",
    "tags": "upcase,python"
}
"""

def main(state):
    if state.text:
        state.text = state.text.upper()

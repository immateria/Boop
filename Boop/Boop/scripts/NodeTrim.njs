/**
{
    "api": 1,
    "name": "Node Trim",
    "description": "Trims whitespace using Node.js",
    "author": "Codex",
    "icon": "scissors",
    "tags": "trim,node"
}
*/
exports.main = function(state){
  if(state.text){
    state.text = state.text.trim();
  }
};

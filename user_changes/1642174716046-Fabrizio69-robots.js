//Fabrizio69
//
//&<h3>Field changed in robot manager</h3><br><ul><li>ID: <ins>2</ins><ul><li>current_version: v<del>1</del><b>2</b>.<del>4</del><b>8</b></li><li>current_version_array: v<del>1</del><b>2</b>.<del>4</del><b>8</b></li></ul></li></ul>
db.robots.update ({id: 2},{$set: { current_version: "v2.8", current_version_array: "v2.8"}});

//traversaro
//&<h3>Field changed in robot manager</h3><br><ul><li>ID: <ins>31</ins><ul><li>os_version: <del>3</del><b>7</b>.0</li><li>os_version_array: <del>3</del><b>7</b>.0</li></ul></li></ul>
db.robots.update ({id: 31},{$set: { os_version: "7.0", os_version_array: "7.0"}});

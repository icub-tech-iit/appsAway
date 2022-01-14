//Fabrizio69
//
//&<h3>Field changed in robot manager</h3><br><ul><li>ID: <ins>2</ins><ul><li>sensors: [/dev/<del>bo</del><b>ttyX</b>s<del>ch-i2c-imu</del><b>ens</b>]</li></ul></li></ul>
db.robots.update ({id: 2},{$set: { sensors: ["/dev/ttyXsens"]}});

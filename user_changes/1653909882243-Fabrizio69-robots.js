//Fabrizio69
//
//&<h3>Field changed in robot manager</h3><br><ul><li>ID: <ins>48</ins><ul><li>name: <b>iCubShanghai01</b></li><li>institution_name: <b>FUDAN University, Shanghai</b></li><li>current_version: <b>v2.7</b></li><li>current_version_array: <b>v2.7</b></li><li>color_skin: <del>bl</del><b>Gr</b>a<del>ck</del><b>y</b></li></ul></li></ul>
db.robots.update ({id: 48},{$set: { name: "iCubShanghai01", institution_name: "FUDAN University, Shanghai", current_version: "v2.7", current_version_array: "v2.7", color_skin: "Gray"}});

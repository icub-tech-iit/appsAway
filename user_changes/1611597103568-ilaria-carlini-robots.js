//ilaria-carlini
//&<h3>Field changed in robot manager</h3><br><ul><li>ID: <ins>2</ins><ul><li>current_version: v1.<del>4</del><b>x.1</b></li><li>current_version_array: v1.<del>4</del><b>x.1</b></li><li>production_date: <b>01/01/2021</b></li></ul></li><li>ID: <ins>45</ins><ul><li>id: <b>45</b></li><li>serial_number: <b>045</b></li><li>sub_serial_head: <b>062H</b></li><li>sub_serial_upper: <b>043U</b></li><li>sub_serial_hands_and_forearms: <b>047HF</b></li><li>sub_serial_lower: <b>042LW</b></li><li>sub_serial_legs: <b>043L</b></li><li>name: <b>iCubGenova05</b></li><li>platform: <b>iCub</b></li><li>institution_name: <b></b></li><li>component: <b>["Waist","Left Leg","Right Leg"]</b></li><li>component_array: <b>[]</b></li><li>current_version: <b></b></li><li>current_version_array: <b>[]</b></li><li>head_cpu_type: <b></b></li><li>head_cpu_type_array: <b>[]</b></li><li>color_skin: <b>black</b></li><li>color_body: <b>black</b></li><li>notes: <b></b></li><li>os_version: <b></b></li><li>os_version_array: <b>[]</b></li><li>logic_harness_version: <b></b></li><li>logic_harness_version_array: <b>[]</b></li><li>laboratory_name: <b></b></li><li>laboratory_url: <b></b></li><li>production_date: <b></b></li></ul></li></ul>
db.robots.update ({id: 2},{$set: { current_version: "v1.x.1", current_version_array: "v1.x.1", production_date: "01/01/2021"}});
db.robots.update ({id: 45},{$set: { id: 45, serial_number: "045", sub_serial_head: "062H", sub_serial_upper: "043U", sub_serial_hands_and_forearms: "047HF", sub_serial_lower: "042LW", sub_serial_legs: "043L", name: "iCubGenova05", platform: "iCub", institution_name: "", component: [\"Waist\",\"Left Leg\",\"Right Leg\"], component_array: [], current_version: "", current_version_array: [], head_cpu_type: "", head_cpu_type_array: [], color_skin: "black", color_body: "black", notes: "", os_version: "", os_version_array: [], logic_harness_version: "", logic_harness_version_array: [], laboratory_name: "", laboratory_url: "", production_date: ""}});
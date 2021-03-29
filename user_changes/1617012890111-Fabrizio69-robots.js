//Fabrizio69
//&<h3>Field changed in robot manager</h3><br><ul><li>ID: <ins>45</ins><ul><li>institution_name: <b>University of Zagreb, Zagreb</b></li><li>laboratory_name: <b>Faculty of Mechanical Engineering and Naval Architecture</b></li><li>laboratory_url: <b>https://www.fsb.unizg.hr/index.php?fsbonline_en&lang=en</b></li></ul></li></ul>
db.robots.update ({id: 45},{$set: { institution_name: "University of Zagreb, Zagreb", laboratory_name: "Faculty of Mechanical Engineering and Naval Architecture", laboratory_url: "https://www.fsb.unizg.hr/index.php?fsbonline_en&lang=en"}});

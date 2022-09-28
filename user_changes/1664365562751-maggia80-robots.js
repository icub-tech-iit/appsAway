//maggia80
//
//&<h3>Field changed in robot manager</h3><br><ul><li>ID: <ins>39</ins><ul><li>color_skin: <del>black</del><b>red</b></li></ul></li><li>ID: <ins>40</ins><ul><li>laboratory_name: <b>CONTACT</b></li><li>laboratory_url: <b>https://www.iit.it/it/web/cognitive-architecture-for-collaborative-technologies/home</b></li></ul></li><li>ID: <ins>43</ins><ul><li>color_skin: bl<del>ack</del><b>ue</b></li></ul></li></ul>
db.robots.update ({id: 39},{$set: { color_skin: "red"}});
db.robots.update ({id: 40},{$set: { laboratory_name: "CONTACT", laboratory_url: "https://www.iit.it/it/web/cognitive-architecture-for-collaborative-technologies/home"}});
db.robots.update ({id: 43},{$set: { color_skin: "blue"}});

//traversaro
//&<h3>Field changed in robot manager</h3><br><ul><li>ID: <ins>31</ins><ul><li>notes: <b>Robot equipped with a real battery, as opposed to other 2.5.5, 2.6 and 2.7 that have a fake battery.</b></li></ul></li></ul>
db.robots.update ({id: 31},{$set: { notes: "Robot equipped with a real \"battery\", as opposed to other 2.5.5, 2.6 and 2.7 that have a fake battery."}});

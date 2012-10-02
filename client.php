<?php
require_once 'lib/Complex.php';

$storage = new PostgresStorage(
    new PDO('pgsql:host=127.0.0.1;dbname=postgres', 'postgres', 'lttumvuv')
);

$mapper = new ComplexMapper();
$mapper->setStorage($storage);


$complexFromParams = new Complex(2121, 12);
$complexFromDb = $mapper->fetch();
$complexFromDb->multiply($complexFromParams);
$mapper->update($complexFromDb);

$complexFromDb = new HtmlComplex($complexFromDb);
$complexFromDb->display();
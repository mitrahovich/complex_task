<?php
require_once 'lib/Complex.php';
$host     = '';
$user     = '';
$password = '';

$storage = new PostgresStorage(
    new PDO($host, $user, $password)
);

$mapper = new ComplexMapper();
$mapper->setStorage($storage);


$complexFromParams = new Complex(2121, 12);
$complexFromDb = $mapper->fetch();
$complexFromDb->multiply($complexFromParams);
$mapper->update($complexFromDb);

$complexFromDb = new HtmlComplex($complexFromDb);
$complexFromDb->display();
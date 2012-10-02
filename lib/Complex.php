<?php

interface IStorage {

    public function update(array $data);

    public function fetch();

}

interface IMapper {

    public function update(IModel $complex);

    public function fetch();

    public function setStorage(IStorage $storage);

}

interface IModel {

    public function getId();

    public function toArray();

    public function fromArray(array $params);

}

class Complex {

    private $_real      = null;
    private $_imaginary = null;

    public function __construct($real, $imaginary) {
        $this->_imaginary = (float)$imaginary;
        $this->_real      = (float)$real;
    }

    public function multiply(Complex $c) {
        $this->_real = $this->_real * $c->_real - $this->_imaginary * $c->_imaginary;
        $this->_imaginary = $this->_real * $c->_imaginary + $this->_imaginary * $c->_real;
    }

    public function getImaginary() {
        return $this->_imaginary;
    }

    public function getReal() {
        return $this->_real;
    }

    public function setImaginary($imaginary) {
        $this->_imaginary = $imaginary;
    }

    public function setReal($real) {
        $this->_real = $real;
    }

}

abstract class DisplayedComplex extends Complex{

    private $_complex = null;

    public function __construct(Complex $complex) {
        $this->_complex = $complex;
    }

    protected function _getComplex() {
        return $this->_complex;
    }

    abstract public function display();
}

class HtmlComplex extends DisplayedComplex {

    public function display() {
        echo $this->_getComplex()->getImaginary() . 'i + ' . $this->_getComplex()->getReal();
    }
}

class ConsoleComplex extends DisplayedComplex {

    public function display() {
        echo 'Console комплексное число';
    }
}

class ComplexModel extends Complex implements IModel {

    private $_id;

    public function __construct(array $params) {
        $this->fromArray($params);
    }

    public function getId() {
        return $this->_id;
    }

    public function toArray() {
        return array(
            'id'   => $this->getId(),
            'real' => $this->getReal(),
            'imaginary' => $this->getImaginary()
        );
    }

    public function fromArray(array $params) {
        $this->_id = $params['id'];
        $this->setImaginary($params['imaginary']);
        $this->setReal($params['real']);
    }

}

class PostgresStorage implements IStorage {

    /**
     * @var PDO
     */
    private $_conn = null;

    public function __construct(PDO $conn) {

        $this->_conn = $conn;
    }

    public function fetch() {
        /** @var PDOStatement $statement  */
        $statement =  $this->_conn->query('select * from base.complex_number order by id limit 1');
        return $statement->fetch();
    }

    public function update(array $data) {
        /** @var PDOStatement $statement  */
        $statement = $this->_conn->prepare("
            update base.complex_number
            set real  = :real,
            imaginary = :imaginary
            where id =  :id
        ");
        $statement->execute($data);
    }

}

class TextStorage implements IStorage {

    public function fetch() {

    }

    public function update(array $data) {

    }

}

class ComplexMapper implements IMapper {

    /**
     * @var IStorage
     */
    private $_storage = null;

    public function setStorage(IStorage $storage) {
        $this->_storage = $storage;
    }

    public function fetch() {
        $row = $this->_storage->fetch();
        return new ComplexModel($row);
    }

    public function update(IModel $complex) {
        $data = $complex->toArray();
        $this->_storage->update($data);
    }

}
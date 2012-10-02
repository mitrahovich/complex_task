<?php

interface IBehavior {
    public function doSmth();
}

class Behavior implements IBehavior{
    public function doSmth() {

    }
}

// ���� ������� ��� ���������!
class Client {

    /**
     * @var IBehavior
     */
    private $_behavior;

    //��� ������ �������� �� ����������, � �� �� ���������� �������!
    public function setBehavior(IBehavior $b) {
        $this->_behavior = $b;
    }

    // ����������� ��, ��� ����������!
    // ����������� �� ������ ���������, � �� ����������!
    public function doSmth() {
        $this->_behavior->doSmth();
    }
}
<?php

interface IBehavior {
    public function doSmth();
}

class Behavior implements IBehavior{
    public function doSmth() {

    }
}

// Одна причина для изменения!
class Client {

    /**
     * @var IBehavior
     */
    private $_behavior;

    //Код должен зависеть от абстракций, а не от конкретных классов!
    public function setBehavior(IBehavior $b) {
        $this->_behavior = $b;
    }

    // Инкапслируй то, что изменяется!
    // Програмируй на уровне супертипа, а не реализации!
    public function doSmth() {
        $this->_behavior->doSmth();
    }
}
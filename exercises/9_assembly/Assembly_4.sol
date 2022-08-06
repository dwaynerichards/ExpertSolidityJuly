// I AM NOT DONE

pragma solidity ^0.8.4;
contract Scope {

    uint public count = 10;
    
    function increment(uint numb) public {        

        // Modify state of the count from within 
        // the assembly segment
        assembly {                                 
          //load into stack with .slot
          let c := sload(count.slot)
          //store value at .slot location in store, after incrementing by numb
          sstore(
            count.slot,
            add(numb, c)
            )
          //increment
          //store 
        }
    }    
}

                      
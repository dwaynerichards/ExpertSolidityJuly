// I AM NOT DONE

pragma solidity ^0.8.4;
contract SubOverflow {

    // Modify this function so on overflow it sets value to 0
    function subtract(uint x, uint y) public pure returns (uint) {        

        // Write assembly code that handles overflows        
        assembly {                        
         function getDiff(a,b) => diff {
            let diff := sub(a,b)
            if gt(diff , x) {
                diff := 0
         }
        }
         let differance := getDiff(x,y)
         mstore(0x0, differance)
         return(0x0, 32)
         
    }    
}


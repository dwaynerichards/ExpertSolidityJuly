// I AM NOT DONE

pragma solidity ^0.8.4;
contract Intro {
    function intro() public pure returns (uint16) {   

        uint256 mol = 420;  
          
        // Yul assembly magic happens within assembly{} section
        assembly {            
            // stack variables are isntaniated with 
            // let variable_name := VALUE            

            // instainate stack variable that holds value of mol            
            
            //how would you load value of mol
            let stackVar := mol
            mstore(
                //store at free memory pointer
                0x00,
                stackVar
            )
            return(mload(0x00), 16)
            // To return it needs to be stored in memory
            // with command mstore(MEMORY_LOCATION, STACK_VARIABLE)
            
            
            // to return you need to specify address and the size from the starting point                    
            
        }
    }       
}


// My answer
//  function intro() public pure returns (uint16) {   
// let v := mol
// mstore(0x00, v)  
// return(0x00, 32)       
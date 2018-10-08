// 2004.05.28, 2004.10.20, 2005.01.08, 2005.03.25, 2005.04.28, 2005.07.18, 2005.07.28, 2005.09.19, 2007.12.19, 2008.10.15
//****************************************
//** Copyright (C) W.ch 1999-2008 **
//** Web: http://www.winchiphead.com **
//****************************************
//** DLL for USB interface chip CH341 **
//** C, VC5.0 **
//****************************************
//
// USB bus interface chip CH341 parallel application layer interface library V2.1
// Nanjing Qin Heng Electronics Co., Ltd. Author: W.ch 2008.10
// CH341-DLL V2.1
// Operating Environment: Windows 98/ME, Windows 2000/XP
// support USB chip: CH341, CH341A
// USB => Parallel, I2C, SPI, JTAG ...
//

#ifndef _CH341_DLL_H
#define _CH341_DLL_H

#ifdef __cplusplus
extern "C" {
#endif

#define mOFFSET( s, m ) ( (ULONG) & ((( s * ) 0 ) -> m)) // Define the macro to get the relative offset of the structure member.

#ifndef max
#define max( a, b ) (( (a)> (b)) (a): (b)) // Larger value
#endif

#ifndef min
#define min( a, b ) ( ( (a ) < ( b )) ? ( a ): ( b ) ) // Minor value
#endif

#ifdef ExAllocatePool
#undef ExAllocatePool // Delete memory allocation with TAG
#endif

#ifndef NTSTATUS
typedef LONG NTSTATUS; // return status
#endif


typedef struct _USB_SETUP_PKT { // Data request packet structure of the USB transfer control setup phase
UCHAR mUspReqType; // 00H request type
UCHAR mUspRequest; // 01H request code
union {
struct {
UCHAR mUspValueLow; // 02H value parameter low byte
UCHAR mUspValueHigh; // 03H value parameter high byte
};
USHORT mUspValue; // 02H-03H value parameter
};
union {
struct {
UCHAR mUspIndexLow; // 04H index parameter low byte
UCHAR mUspIndexHigh; // 05H index parameter high byte
};
USHORT mUspIndex; // 04H-05H index parameter
};
USHORT mLength; // Length of data in the data phase of 06H-07H
} mUSB_SETUP_PKT, *mPUSB_SETUP_PKT;


#define mCH341_PACKET_LENGTH 32 // Length of packet supported by CH341
#define mCH341_PKT_LEN_SHORT 8 // Length of short packet supported by CH341


typedef struct _WIN32_COMMAND { // Defines the WIN32 command interface structure
union {
ULONG mFunction; // Specify function code or pipe number when inputting
NTSTATUS mStatus; // Return to operation state on output
};
ULONG mLength; // access length, return the length of subsequent data
union {
mUSB_SETUP_PKT mSetupPkt; // USB transfer request for data transfer during the setup phase
UCHAR mBuffer[ mCH341_PACKET_LENGTH ]; // data buffer, length 0 to 255B
};
} mWIN32_COMMAND, *mPWIN32_COMMAND;


// WIN32 application layer interface commands
#define IOCTL_CH341_COMMAND ( FILE_DEVICE_UNKNOWN << 16 | FILE_ANY_ACCESS << 14 | 0x0f34 << 2 | METHOD_BUFFERED ) // Dedicated interface

#define mWIN32_COMMAND_HEAD mOFFSET( mWIN32_COMMAND, mBuffer ) // Header length of WIN32 command interface

#define mCH341_MAX_NUMBER 16 // The number of CH341s connected at the same time

#define mMAX_BUFFER_LENGTH 0x1000 // Maximum length of data buffer 4096

#define mMAX_COMMAND_LENGTH (mWIN32_COMMAND_HEAD + mMAX_BUFFER_LENGTH) // Maximum data length plus the length of the command structure header

#define mDEFAULT_BUFFER_LEN 0x0400 // The default length of the data buffer is 1024

#define mDEFAULT_COMMAND_LEN (mWIN32_COMMAND_HEAD + mDEFAULT_BUFFER_LEN) // The default data length plus the length of the command structure header


// CH341 endpoint address
#define mCH341_ENDP_INTER_UP 0x81 // address of the CH341 interrupt data upload endpoint
#define mCH341_ENDP_INTER_DOWN 0x01 // CH341 interrupt data downlink address of endpoint
#define mCH341_ENDP_DATA_UP 0x82 // address of the CH341 data block upload endpoint
#define mCH341_ENDP_DATA_DOWN 0x02 // The address of the endpoint of the CH341 data block


// The pipeline operation command provided by the device layer interface
#define mPipeDeviceCtrl 0x00000004 // Integrated control pipeline for CH341
#define mPipeInterUp 0x00000005 // CH 341 interrupt data upload pipe
#define mPipeDataUp 0x00000006 // block upload pipeline for CH341
#define mPipeDataDown 0x00000007 // Downstream pipe of CH341 data block

// Function code of application layer interface
#define mFuncNoOperation 0x00000000 // No action
#define mFuncGetVersion 0x00000001 // Get driver version number
#define mFuncGetConfig 0x00000002 // Get USB device configuration descriptor
#define mFuncSetTimeout 0x00000009 // Set timeout for USB communication
#define mFuncSetExclusive 0x0000000b // set exclusive use
#define mFuncResetDevice 0x0000000c // Reset USB Device
#define mFuncResetPipe 0x0000000d // reset USB pipe
#define mFuncAbortPipe 0x0000000e // Cancel USB pipe data request

// CH 341 dedicated function code
#define mFuncSetParaMode 0x0000000f // Set parallel port mode
#define mFuncReadData0 0x00000010 // Read data block 0 from parallel port
#define mFuncReadData1 0x00000011 // Read data block 1 from parallel port
#define mFuncWriteData0 0x00000012 // Write data block 0 to parallel port
#define mFuncWriteData1 0x00000013 // Write data block 1 to parallel port
#define mFuncWriteRead 0x00000014 // Output first and then input
#define mFuncBufferMode 0x00000020 // Set the buffer upload mode and the data length in the query buffer
#define mFuncBufferModeDn 0x00000021 // Set the data length in buffer down mode and query buffer


// USB device standard request code
#define mUSB_CLR_FEATURE 0x01
#define mUSB_SET_FEATURE 0x03
#define mUSB_GET_STATUS 0x00
#define mUSB_SET_ADDRESS 0x05
#define mUSB_GET_DESCR 0x06
#define mUSB_SET_DESCR 0x07
#define mUSB_GET_CONFIG 0x08
#define mUSB_SET_CONFIG 0x09
#define mUSB_GET_INTERF 0x0a
#define mUSB_SET_INTERF 0x0b
#define mUSB_SYNC_FRAME 0x0c

// Manufacturer-specific request type for CH341 control transfer
#define mCH341_VENDOR_READ 0xC0 // Manufacturer-specific read operation of CH341 via control transfer
#define mCH341_VENDOR_WRITE 0x40 // CH341 manufacturer-specific write operation via control transfer

// Vendor-specific request code for CH341 control transfer
#define mCH341_PARA_INIT 0xB1 // Initialize the parallel port
#define mCH341_I2C_STATUS 0x52 // Get the status of the I2C interface
#define mCH341_I2C_COMMAND 0x53 // Command to issue I2C interface

// CH341 parallel operation command code
#define mCH341_PARA_CMD_R0 0xAC // Read data from parallel port 0, bytes are length
#define mCH341_PARA_CMD_R1 0xAD // read data from parallel port 1, byte size is length
#define mCH341_PARA_CMD_W0 0xA6 // Write 0 to the parallel port, starting with the subbyte
#define mCH341_PARA_CMD_W1 0xA7 // Write data 1 to the parallel port, starting from the subbyte to the data stream
#define mCH341_PARA_CMD_STS 0xA0 // Get the parallel port status

// CH341A parallel operation command code
#define mCH341A_CMD_SET_OUTPUT 0xA1 // Set the parallel output
#define mCH341A_CMD_IO_ADDR 0xA2 // MEM with address read/write input/output, starting from sub-byte for command flow
#define mCH341A_CMD_PRINT_OUT 0xA3 // PRINT compatible print mode output, starting from sub-byte for data stream
#define mCH341A_CMD_PWM_OUT 0xA4 // Command packet for PWM data output, starting from sub-byte for data flow
#define mCH341A_CMD_SHORT_PKT 0xA5 // Short packet, sub-byte is the real length of the command packet, bytes again and after the original command packet
#define mCH341A_CMD_SPI_STREAM 0xA8 // Command packet for SPI interface, starting from sub-byte for data flow
//#define mCH341A_CMD_SIO_STREAM 0xA9 //The command packet of the SIO interface, starting from the subbyte as the data stream
#define mCH341A_CMD_I2C_STREAM 0xAA // Command packet for the I2C interface, starting from the subbyte to the I2C command stream
#define mCH341A_CMD_UIO_STREAM 0xAB // A command packet for the UIO interface, starting with the sub-byte for the command flow
#define mCH341A_CMD_PIO_STREAM 0xAE // Command packet of PIO interface, starting from sub-byte for data flow

// Vendor-specific request code for CH341A control transfer
#define mCH341A_BUF_CLEAR 0xB2 // Clear unfinished data
#define mCH341A_I2C_CMD_X 0x54 // Command to issue I2C interface, execute immediately
#define mCH341A_DELAY_MS 0x5E // delay the specified time in leap second
#define mCH341A_GET_VER 0x5F // Get the chip version

#define mCH341_EPP_IO_MAX (mCH341_PACKET_LENGTH - 1 ) // Maximum length of a single read/write data block in CHEP in EPP/MEM mode
#define mCH341A_EPP_IO_MAX 0xFF // Maximum length of a single read/write data block in CHEP EPE/MEM mode

#define mCH341A_CMD_IO_ADDR_W 0x00 // MEM command flow with address read/write/input/output: write data, bit 6 - bit 0 is the address, the next byte is the data to be written
#define mCH341A_CMD_IO_ADDR_R 0x80 // MEM with address read/write/input/output command stream: read data, bit 6 - bit 0 is address, read data return together

#define mCH341A_CMD_I2C_STM_STA 0x74 // Command flow for I2C interface: Start bit generation
#define mCH341A_CMD_I2C_STM_STO 0x75 // Command Flow of I2C Interface: Generate Stop Bits
#define mCH341A_CMD_I2C_STM_OUT 0x80 //Command flow of I2C interface: output data, bit 5-bit 0 is length, subsequent bytes are data, 0 length only sends one byte and return reply
#define mCH341A_CMD_I2C_STM_IN 0xC0 // Command flow of I2C interface: input data, bit 5-bit 0 is length, 0 length only receives one byte and sends no reply
#define mCH341A_CMD_I2C_STM_MAX ( min( 0x3F, mCH341_PACKET_LENGTH )) // Maximum length of command input/output data for a single command stream of the I2C interface
#define mCH341A_CMD_I2C_STM_SET 0x60 // Command flow of I2C interface: set parameters, bit 2 = number of SPI I/O (0=single in single out, 1=double in double out), bit 1 bit 0=I2C speed (00= Low speed, 01=standard, 10=fast, 11=high speed)
#define mCH341A_CMD_I2C_STM_US 0x40 // Command flow of I2C interface: delay in microseconds, bit 3-bit 0 is the delay value
#define mCH341A_CMD_I2C_STM_MS 0x50 // Command flow of I2C interface: delay in units of leap second, bit 3 - bit 0 is the delay value
#define mCH341A_CMD_I2C_STM_DLY 0x0F // Maximum number of command flow delays per I2C interface
#define mCH341A_CMD_I2C_STM_END 0x00 // Command flow of I2C interface: Command packet ends prematurely

#define mCH341A_CMD_UIO_STM_IN 0x00 // Command flow for UIO interface: input data D7-D0
#define mCH341A_CMD_UIO_STM_DIR 0x40 //Command flow of UIO interface: set I/O direction D5-D0, bit 5-bit 0 is direction data
#define mCH341A_CMD_UIO_STM_OUT 0x80 // Command flow of UIO interface: output data D5-D0, bit 5-bit 0 is data
#define mCH341A_CMD_UIO_STM_US 0xC0 // Command flow of UIO interface: delay in microseconds, bit 5-bit 0 is the delay value
#define mCH341A_CMD_UIO_STM_END 0x20 // Command Flow of UIO Interface: Command Package Ends Early


// CH341 parallel port operation mode
#define mCH341_PARA_MODE_EPP 0x00 // CH341 parallel port work mode is EPP mode
#define mCH341_PARA_MODE_EPP17 0x00 // CH341A parallel port work mode is EPP mode V1.7
#define mCH341_PARA_MODE_EPP19 0x01 // CH341A parallel port work mode is EPP mode V1.9
#define mCH341_PARA_MODE_MEM 0x02 // CH341 parallel port work mode is MEM mode
#define mCH341_PARA_MODE_ECP 0x03 // CH341A parallel port work mode is ECP mode


// I/O Direction Setting Bit Definition, Bit Definition of Direct Input Status Signal, Direct Output Bit Data Definition
#define mStateBitERR 0x00000100 // Read-only writable, ERR# pin input state, 1: high level, 0: low level
#define mStateBitPEMP 0x00000200 // Read-only writable, PEMP pin input state, 1: high level, 0: low level
#define mStateBitINT 0x00000400 // Read-only writable, INT# pin input state, 1: high level, 0: low level
#define mStateBitSLCT 0x00000800 // Read-only writable, SLCT pin input state, 1: high level, 0: low level
#define mStateBitWAIT 0x00002000 // Read-only writable, WAIT# pin input state, 1: high level, 0: low level
#define mStateBitDATAS 0x00004000 // Read-only, DATAS#/READ# pin input status, 1: high, 0: low
#define mStateBitADDRS 0x00008000 // Write-only, ADDRS#/ADDR/ALE pin input state, 1: high level, 0: low level
#define mStateBitRESET 0x00010000 // Write only, RESET# pin input status, 1: high level, 0: low level
#define mStateBitWRITE 0x00020000 // Write only, WRITE# pin input status, 1: high level, 0: low level
#define mStateBitSCL 0x00400000 // Read only, SCL pin input state, 1: high level, 0: low level
#define mStateBitSDA 0x00800000 // Read only, SDA pin input state, 1: High level, 0: Low level


#define MAX_DEVICE_PATH_SIZE 128 // Maximum number of characters for the device name
#define MAX_DEVICE_ID_SIZE 64 // Maximum number of characters for device ID


typedef VOID ( CALLBACK * mPCH341_INT_ROUTINE ) ( // Interrupt service routine
ULONG iStatus ); // Interrupt status data, refer to the following bit description
// Bit 7-bit 0 corresponds to the D7-D0 pin of the CH341
// Bit 8 corresponds to the ERR# pin of CH341, Bit 9 corresponds to the PEMP pin of CH341, Bit 10 corresponds to the INT# pin of CH341, and Bit 11 corresponds to the SLCT pin of CH341.


HANDLE WINAPI CH341OpenDevice( // Open CH341 device, return handle, error is invalid
ULONG iIndex ); // Specify CH341 device serial number, 0 corresponds to the first device


VOID WINAPI CH341CloseDevice( // shut down the CH341 device
ULONG iIndex ); // Specify CH341 device serial number


ULONG WINAPI CH341GetVersion (); // Get the DLL version number, return the version number


ULONG WINAPI CH341DriverCommand( // Pass the command directly to the driver, return 0 if there is an error, otherwise return the data length
ULONG iIndex, // ​​specify CH341 device serial number, V1.6 or above DLL can also be a handle after the device is opened
mPWIN32_COMMAND ioCommand ); // pointer to the command structure
// The program returns the data length after the call, and still returns the command structure. If it is a read operation, the data is returned in the command structure.
// The returned data length is 0 when the operation fails, and the length of the entire command structure when the operation is successful. For example, when reading a byte, mWIN32_COMMAND_HEAD+1 is returned.
// Before the command structure is invoked, provide: pipe number or command function code, access data length (optional), data (optional)
// After the command structure is called, return: the operation status code, the length of the subsequent data (optional),
// The operation status code is the code defined by WINDOWS. It can refer to NTSTATUS.H,
// The length of the subsequent data refers to the length of the data returned by the read operation. The data is stored in the subsequent buffer and is generally 0 for write operations.


ULONG WINAPI CH341GetDrvVersion( ); // Get driver version number, return version number, error returns 0


BOOL WINAPI CH341ResetDevice( // reset USB device
ULONG iIndex ); // Specify CH341 device serial number


BOOL WINAPI CH341GetDeviceDescr( // Read device descriptor
ULONG iIndex, // Specify CH341 device serial number
PVOID oBuffer, // Point to a large enough buffer to hold the descriptor
PULONG ioLength ); // Point to the length of the unit, when the input is ready to read the length, the actual length of the read after the return


BOOL WINAPI CH341GetConfigDescr( // Read configuration descriptor
ULONG iIndex, // Specify CH341 device serial number
PVOID oBuffer, // Point to a large enough buffer to hold the descriptor
PULONG ioLength ); // Point to the length of the unit, when the input is ready to read the length, the actual length of the read after the return


BOOL WINAPI CH341SetIntRoutine( // Sets the interrupt service routine
ULONG iIndex, // Specify CH341 device serial number
mPCH341_INT_ROUTINE iIntRoutine ); // Specifies the interrupt service routine. If NULL, the interrupt service is cancelled. Otherwise, the program is called on interrupt.


BOOL WINAPI CH341ReadInter( // Read interrupt data
ULONG iIndex, // Specify CH341 device serial number
PULONG iStatus ); // Point to a double word unit, used to save the read interrupt status data, see the down
// Bit 7-bit 0 corresponds to the D7-D0 pin of the CH341
// Bit 8 corresponds to the ERR# pin of CH341, Bit 9 corresponds to the PEMP pin of CH341, Bit 10 corresponds to the INT# pin of CH341, and Bit 11 corresponds to the SLCT pin of CH341.


BOOL WINAPI CH341AbortInter( // Give up interrupt data read operation
ULONG iIndex ); // Specify CH341 device serial number


BOOL WINAPI CH341SetParaMode( // set parallel port mode
ULONG iIndex, // Specify CH341 device serial number
ULONG iMode ); // Specify the parallel mode: 0 is EPP mode/EPP mode V1.7, 1 is EPP mode V1.9, 2 is MEM mode


BOOL WINAPI CH341InitParallel( // Reset and initialize parallel port, RST# outputs low pulse
ULONG iIndex, // Specify CH341 device serial number
ULONG iMode ); // Specify the parallel mode: 0 is EPP mode/EPP mode V1.7, 1 is EPP mode V1.9, 2 is MEM mode, >= 0x00000100 Keep current mode


BOOL WINAPI CH341ReadData0( // Read data block from 0# port
ULONG iIndex, // Specify CH341 device serial number
PVOID oBuffer, // Point to a large enough buffer to hold the read data
PULONG ioLength ); // Point to the length of the unit, when the input is ready to read the length, the actual length of the read after the return


BOOL WINAPI CH341ReadData1( // Read data block from port 1#
ULONG iIndex, // Specify CH341 device serial number
PVOID oBuffer, // Point to a large enough buffer to hold the read data
PULONG ioLength ); // Point to the length of the unit, when the input is ready to read the length, the actual length of the read after the return


BOOL WINAPI CH341AbortRead( // Discard block reads
ULONG iIndex ); // Specify CH341 device serial number


BOOL WINAPI CH341WriteData0( // Write out data block to 0# port
ULONG iIndex, // Specify CH341 device serial number
PVOID iBuffer, // Point to a buffer, put the data ready for writing
PULONG ioLength ); // Point to the length of the unit, when the input is ready to write the length, the length of the actual write after return


BOOL WINAPI CH341WriteData1( // Write data block to port 1#
ULONG iIndex, // Specify CH341 device serial number
PVOID iBuffer, // Point to a buffer, put the data ready for writing
PULONG ioLength ); // Point to the length of the unit, when the input is ready to write the length, the length of the actual write after return


BOOL WINAPI CH341AbortWrite( // Discard block write operation
ULONG iIndex ); // Specify CH341 device serial number


BOOL WINAPI CH341GetStatus( // Direct input of data and status via CH341
ULONG iIndex, // Specify CH341 device serial number
PULONG iStatus ); // Point to a double word unit for saving state data, refer to the following bit description
// Bit 7-bit 0 corresponds to the D7-D0 pin of the CH341
// Bit 8 corresponds to the ERR# pin of CH341, Bit 9 corresponds to the PEPLP pin of CH341, Bit 10 corresponds to the INT# pin of CH341, Bit 11 corresponds to the SLCT pin of CH341, Bit 23 corresponds to the SDA pin of CH341.
// Bit 13 corresponds to the BUSY/WAIT# pin of CH341, Bit 14 corresponds to the AUTOFD#/DATAS# pin of CH341 and Bit 15 corresponds to the SLCTIN#/ADDRS# pin of CH341


BOOL WINAPI CH341ReadI2C( // Read one byte of data from I2C interface
ULONG iIndex, // Specify CH341 device serial number
UCHAR iDevice, // lower 7 bits specify I2C device address
UCHAR iAddr, // Specify the address of the data unit
PUCHAR oByte ); // point to a byte unit used to save the read byte data


BOOL WINAPI CH341WriteI2C( // Write a byte of data to the I2C interface
ULONG iIndex, // Specify CH341 device serial number
UCHAR iDevice, // lower 7 bits specify I2C device address
UCHAR iAddr, // Specify the address of the data unit
UCHAR iByte ); // byte data to be written


BOOL WINAPI CH341EppReadData( // EPP read data: WR#=1, DS#=0, AS#=1, D0-D7=input
ULONG iIndex, // Specify CH341 device serial number
PVOID oBuffer, // Point to a large enough buffer to hold the read data
PULONG ioLength ); // Point to the length of the unit, when the input is ready to read the length, the actual length of the read after the return


BOOL WINAPI CH341EppReadAddr( // EPP read address: WR#=1, DS#=1, AS#=0, D0-D7=input
ULONG iIndex, // Specify CH341 device serial number
PVOID oBuffer, // Point to a large enough buffer to hold the read address data
PULONG ioLength ); // Point to the length of the unit, when the input is ready to read the length, the actual length of the read after the return


BOOL WINAPI CH341EppWriteData( // Write data in EPP mode: WR#=0, DS#=0, AS#=1, D0-D7=output
ULONG iIndex, // Specify CH341 device serial number
PVOID iBuffer, // Point to a buffer, put the data ready for writing
PULONG ioLength ); // Point to the length of the unit, when the input is ready to write the length, the length of the actual write after return


BOOL WINAPI CH341EppWriteAddr( // EPP write address: WR#=0, DS#=1, AS#=0, D0-D7=output
ULONG iIndex, // Specify CH341 device serial number
PVOID iBuffer, // Point to a buffer, place the address data ready for writing
PULONG ioLength ); // Point to the length of the unit, when the input is ready to write the length, the length of the actual write after return


BOOL WINAPI CH341EppSetAddr( // EPP mode setting address: WR#=0, DS#=1, AS#=0, D0-D7=output
ULONG iIndex, // Specify CH341 device serial number
UCHAR iAddr ); // Specify the EPP address


BOOL WINAPI CH341MemReadAddr0( // MEM mode reads address 0: WR#=1, DS#/RD#=0, AS#/ADDR=0, D0-D7=input
ULONG iIndex, // Specify CH341 device serial number
PVOID oBuffer, // points to a large enough buffer to hold data read from address 0
PULONG ioLength ); // Point to the length of the unit, when the input is ready to read the length, the actual length of the read after the return


BOOL WINAPI CH341MemReadAddr1( // MEM mode read address 1: WR#=1, DS#/RD#=0, AS#/ADDR=1, D0-D7=input
ULONG iIndex, // Specify CH341 device serial number
PVOID oBuffer, // points to a large enough buffer to hold data read from address 1
PULONG ioLength ); // Point to the length of the unit, when the input is ready to read the length, the actual length of the read after the return


BOOL WINAPI CH341MemWriteAddr0( // MEM mode write address 0: WR#=0, DS#/RD#=1, AS#/ADDR=0, D0-D7=output
ULONG iIndex, // Specify CH341 device serial number
PVOID iBuffer, // points to a buffer and places data ready to address 0
PULONG ioLength ); // Point to the length of the unit, when the input is ready to write the length, the length of the actual write after return


BOOL WINAPI CH341MemWriteAddr1( // Write address 1 in MEM mode: WR#=0, DS#/RD#=1, AS#/ADDR=1, D0-D7=output
ULONG iIndex, // Specify CH341 device serial number
PVOID iBuffer, // Point to a buffer, put the data ready to write to address 1
PULONG ioLength ); // Point to the length of the unit, when the input is ready to write the length, the length of the actual write after return


BOOL WINAPI CH341SetExclusive( // set exclusive use of current CH341 device
ULONG iIndex, // Specify CH341 device serial number
ULONG iExclusive ); // 0 means the device can be shared, non-zero exclusive use


BOOL WINAPI CH341SetTimeout( // set USB data read/write timeout
ULONG iIndex, // Specify CH341 device serial number
ULONG iWriteTimeout, // ​​Specify the USB write data block timeout time in milliseconds mS, 0xFFFFFFFF specified does not timeout (default)
ULONG iReadTimeout ); // Specify the USB read data block timeout time in milliseconds mS, 0xFFFFFFFF specified does not timeout (default)


BOOL WINAPI CH341ReadData( // Read data block
ULONG iIndex, // Specify CH341 device serial number
PVOID oBuffer, // Point to a large enough buffer to hold the read data
PULONG ioLength ); // Point to the length of the unit, when the input is ready to read the length, the actual length of the read after the return


BOOL WINAPI CH341WriteData( // Write data block
ULONG iIndex, // Specify CH341 device serial number
PVOID iBuffer, // Point to a buffer, put the data ready for writing
PULONG ioLength ); // Point to the length of the unit, when the input is ready to write the length, the length of the actual write after return


PVOID WINAPI CH341GetDeviceName( // returns a buffer pointing to the name of the CH341 device, returning NULL on error
ULONG iIndex ); // Specify CH341 device serial number, 0 corresponds to the first device


ULONG WINAPI CH341GetVerIC( // Get version of CH341 chip, return: 0= device invalid, 0x10=CH341, 0x20=CH341A
ULONG iIndex ); // Specify CH341 device serial number
#define IC_VER_CH341A 0x20
#define IC_VER_CH341A3 0x30


BOOL WINAPI CH341FlushBuffer (//empty CH341 buffer
ULONG iIndex ); // Specify CH341 device serial number


BOOL WINAPI CH341WriteRead( // Execute data stream command, output first and then input
ULONG iIndex, // Specify CH341 device serial number
ULONG iWriteLength, // Write length, ready to write length
PVOID iWriteBuffer, // points to a buffer and places data ready for writing
ULONG iReadStep, // The length of the single block to be read, the total length of the read is (iReadStep*iReadTimes)
ULONG iReadTimes, // Ready to Read
PULONG oReadLength, // ​​point to the length unit, the actual length of the read after return
PVOID oReadBuffer ); // Point to a large enough buffer to hold the read data


BOOL WINAPI CH341SetStream( // Set the serial flow mode
ULONG iIndex, // Specify CH341 device serial number
ULONG iMode ); // specify the mode, see the down
// Bit 1-bit 0: I2C interface speed/SCL frequency, 00=low speed/20KHz, 01=standard/100KHz (default), 10=fast/400KHz, 11=high speed/750KHz
// Bit 2: SPI's I/O count/IO pin, 0 = single in single out (D3 clock/D5 out/D7 in) (default), 1 = double in double out (D3 clock/D5 out D4 Out / D7 into D6 into)
// bit 7: bit order in the SPI byte, 0=low end first, 1=high end first
// other reservations, must be 0


BOOL WINAPI CH341SetDelaymS( // set the hardware asynchronous delay, return soon after the call, and delay the specified number of milliseconds before the next stream operation
ULONG iIndex, // Specify CH341 device serial number
ULONG iDelay ); // Specifies the delay in milliseconds


BOOL WINAPI CH341StreamI2C( // Processing I2C data stream, 2-wire interface, clock line SCL pin, data line SDA pin (quasi-bidirectional I/O), speed about 56K bytes
ULONG iIndex, // Specify CH341 device serial number
ULONG iWriteLength, // The number of data bytes to be written
PVOID iWriteBuffer, // Point to a buffer, place the data ready for writing, the first byte is usually the I2C device address and read-write direction bit
ULONG iReadLength, // The number of data bytes to be read
PVOID oReadBuffer ); // points to a buffer and returns the read data


typedef enum _EEPROM_TYPE { // EEPROM model
ID_24C01,
ID_24C02,
ID_24C04,
ID_24C08,
ID_24C16,
ID_24C32,
ID_24C64,
ID_24C128,
ID_24C256,
ID_24C512,
ID_24C1024,
ID_24C2048,
ID_24C4096
} EEPROM_TYPE;


BOOL WINAPI CH341ReadEEPROM( // Read block from EEPROM, about 56K bytes
ULONG iIndex, // Specify CH341 device serial number
EEPROM_TYPE iEepromID, // specify the EEPROM model
ULONG iAddr, // specify the address of the data unit
ULONG iLength, // The number of data bytes to be read
PUCHAR oBuffer ); // Point to a buffer, read back after the data is returned


BOOL WINAPI CH341WriteEEPROM( // Write data block to EEPROM
ULONG iIndex, // Specify CH341 device serial number
EEPROM_TYPE iEepromID, // specify the EEPROM model
ULONG iAddr, // specify the address of the data unit
ULONG iLength, // The number of data bytes to be written
PUCHAR iBuffer ); // points to a buffer and places data ready for writing


BOOL WINAPI CH341GetInput( // Direct input of data and status via CH341, higher efficiency than CH341GetStatus
ULONG iIndex, // Specify CH341 device serial number
PULONG iStatus ); // Point to a double word unit for saving state data, refer to the following bit description
// Bit 7-bit 0 corresponds to the D7-D0 pin of the CH341
// Bit 8 corresponds to the ERR# pin of CH341, Bit 9 corresponds to the PEPLP pin of CH341, Bit 10 corresponds to the INT# pin of CH341, Bit 11 corresponds to the SLCT pin of CH341, Bit 23 corresponds to the SDA pin of CH341.
// Bit 13 corresponds to the BUSY/WAIT# pin of CH341, Bit 14 corresponds to the AUTOFD#/DATAS# pin of CH341 and Bit 15 corresponds to the SLCTIN#/ADDRS# pin of CH341


BOOL WINAPI CH341SetOutput( // Set I/O direction of CH341 and output data directly through CH341
/* ***** Use this API sparingly to prevent the I/O direction from being changed so that the input pin becomes an output pin, resulting in a short circuit with other output pins that damages the chip. ***** */
ULONG iIndex, // Specify CH341 device serial number
ULONG iEnable, // data valid flag, refer to the following bit description
// Bit 0 is 1 to indicate bit 15 - bit 8 of iSetDataOut is valid, otherwise ignored
// Bit 1 is 1 to indicate bit 15 - bit 8 of iSetDirOut is valid, otherwise ignored
// Bit 2 is 1 to indicate that 7-bit 0 of iSetDataOut is valid, otherwise ignored
// Bit 3 is 1 to indicate that bit 7-bit 0 of iSetDirOut is valid, otherwise it is ignored
// bit 4 is 1 to indicate bit 23-bit 16 of iSetDataOut is valid, otherwise ignored
ULONG iSetDirOut, // Set the I/O direction. If a bit is cleared to 0, the corresponding pin is input. If a bit is set to 1, the corresponding pin is output. In parallel mode, the default value is 0x000FC000. Refer to the following bit description.
ULONG iSetDataOut ); // Output data, if the I/O direction is output, then when the bit is cleared to 0, the corresponding pin outputs low level. When a bit is set to 1, the corresponding pin outputs high level, refer to the following bit description
// Bit 7-bit 0 corresponds to the D7-D0 pin of the CH341
// Bit 8 corresponds to the ERR# pin of CH341, Bit 9 corresponds to the PEMP pin of CH341, Bit 10 corresponds to the INT# pin of CH341, and Bit 11 corresponds to the SLCT pin of CH341.
// Bit 13 corresponds to the WAIT# pin of CH341, Bit 14 corresponds to the DATAS#/READ# pin of CH341, Bit 15 corresponds to the ADDRS#/ADDR/ALE pin of CH341
// The following pins can only be output, regardless of the I/O direction: Bit 16 corresponds to the RESET# pin of CH341, Bit 17 corresponds to the WRITE# pin of CH341, Bit 18 corresponds to the SCL pin of CH341, Bit 29 corresponds to CH341 SDA pin


BOOL WINAPI CH341Set_D5_D0( // Set the I/O direction of the D5-D0 pin of CH341 and output data directly through the D5-D0 pin of CH341, which is more efficient than CH341SetOutput.
/* ***** Use this API sparingly to prevent the I/O direction from being changed so that the input pin becomes an output pin, resulting in a short circuit with other output pins that damages the chip. ***** */
ULONG iIndex, // Specify CH341 device serial number
ULONG iSetDirOut, // Set the I/O direction of each pin of D5-D0. If a bit is cleared to 0, the corresponding pin is an input. If a bit is set to 1, the corresponding pin is output. In parallel mode, the default value is 0x00.
ULONG iSetDataOut ); // Set the output data of each pin of D5-D0. If the I/O direction is output, then when a bit is cleared to 0, the corresponding pin outputs low level. When a bit is set to 1, the corresponding pin outputs high level.
// Bits 5-bit 0 of the above data correspond to the D5-D0 pin of the CH341, respectively


BOOL WINAPI CH341StreamSPI3(// This API has expired, please do not use it
ULONG iIndex,
ULONG iChipSelect,
ULONG iLength,
PVOID ioBuffer );


BOOL WINAPI CH341StreamSPI4( // Processing SPI data stream, 4-wire interface, clock line is DCK/D3 pin, output data line is DOUT/D5 pin, input data line is DIN/D7 pin, chip select line is D0/ D1/D2, speed about 68K bytes
/* SPI timing: DCK/D3 pin is clock output, default is low level, DOUT/D5 pin is output during low period before clock rising edge, DIN/D7 pin is high power before falling clock edge During the flat input */
ULONG iIndex, // Specify CH341 device serial number
ULONG iChipSelect, // Chip select control. Bit 7 is 0 to ignore chip select control. Bit 7 is 1 and the parameter is valid: Bit 1 Bit 0 is 00/01/10 Select D0/D1/D2 pin as low level respectively Effective chip selection
ULONG iLength, // The number of bytes of data to be transferred
PVOID ioBuffer ); // Point to a buffer, place the data to be written out from DOUT, and return the data read from DIN


BOOL WINAPI CH341StreamSPI5( // Process SPI data stream, 5-wire interface, clock line is DCK/D3 pin, output data line is DOUT/D5 and DOUT2/D4 pin, input data line is DIN/D7 and DIN2/D6 Foot, chip select line D0/D1/D2, speed about 30K bytes *2
/* SPI timing: DCK/D3 pin is clock output, default is low level, DOUT/D5 and DOUT2/D4 pins are output during low level before clock rising edge, DIN/D7 and DIN2/D6 pins Input during the high period before the clock falling edge */ 
ULONG iIndex, // Specify CH341 device serial number
ULONG iChipSelect, // Chip select control. Bit 7 is 0 to ignore chip select control. Bit 7 is 1 and the parameter is valid: Bit 1 Bit 0 is 00/01/10 Select D0/D1/D2 pin as low level respectively Effective chip selection
ULONG iLength, // The number of bytes of data to be transferred
PVOID ioBuffer, // points to a buffer, places data to be written from DOUT, and returns data read from DIN
PVOID ioBuffer2 ); // points to the second buffer, places the data to be written from DOUT2, and returns the data read from DIN2.


BOOL WINAPI CH341BitStreamSPI( // Processing SPI bit stream, 4-wire / 5-wire interface, clock line is DCK/D3 pin, output data line is DOUT/DOUT2 pin, input data line is DIN/DIN2 pin, chip select The line is D0/D1/D2 and the speed is about 8K bits*2
ULONG iIndex, // Specify CH341 device serial number
ULONG iLength, // The number of data bits to be transmitted, up to 896 at a time, it is recommended not to exceed 256
PVOID ioBuffer ); // points to a buffer, places data to be written from DOUT/DOUT2/D2-D0, and returns data read from DIN/DIN2
/* SPI timing: DCK/D3 pin is clock output, default is low level, DOUT/D5 and DOUT2/D4 pins are output during low level before clock rising edge, DIN/D7 and DIN2/D6 pins Input */ 
/* during the high period before the clock falling edge A total of 8 bits of a byte in the */
/* ioBuffer correspond to the D7-D0 pin, Bit 5 is output to DOUT, Bit 4 is output to DOUT2, Bit 2 - Bit 0 is output to D2-D0, Bit 7 is input from DIN, Bit 6 Input from DIN2, bit 3 data ignored */
/* Before calling this API, you should first call CH341Set_D5_D0 to set the I/O direction of the D5-D0 pin of CH341 and set the default level of the pin */


BOOL WINAPI CH341SetBufUpload( // Set internal buffer upload mode
ULONG iIndex, // Specify CH341 device serial number, 0 corresponds to the first device
ULONG iEnableOrClear ); // 0 disables internal buffer upload mode, uses direct upload, nonzero enables internal buffer upload mode and clears existing data in buffer
// If the internal buffer upload mode is enabled, the CH341 driver creation thread will automatically receive the USB upload data to the internal buffer and clear the existing data in the buffer. When the application calls CH341ReadData, it will immediately return to the existing buffer. data


LONG WINAPI CH341QueryBufUpload( // Query the number of existing packets in the internal upload buffer, the number of packets returned successfully, error returns -1
ULONG iIndex ); // Specify CH341 device serial number, 0 corresponds to the first device


BOOL WINAPI CH341SetBufDownload( // set internal buffer download mode
ULONG iIndex, // Specify CH341 device serial number, 0 corresponds to the first device
ULONG iEnableOrClear ); // 0 disables internal buffer download mode, use direct download, nonzero enables internal buffer download mode and clears existing data in buffer
// If the internal buffer download mode is enabled, when the application calls CH341WriteData, it will only put the USB downstream data into the internal buffer and immediately return, and the thread created by the CH341 driver is automatically sent until the completion.


LONG WINAPI CH341QueryBufDownload( // Query the number of remaining packets in the internal downlink buffer (not yet sent). Returns the number of packets successfully. Error returns -1
ULONG iIndex ); // Specify CH341 device serial number, 0 corresponds to the first device


BOOL WINAPI CH341ResetInter( // reset interrupt data read operation
ULONG iIndex ); // Specify CH341 device serial number


BOOL WINAPI CH341ResetRead( // Reset data block read operation
ULONG iIndex ); // Specify CH341 device serial number


BOOL WINAPI CH341ResetWrite( // Reset block write operation
ULONG iIndex ); // Specify CH341 device serial number


typedef VOID ( CALLBACK * mPCH341_NOTIFY_ROUTINE ) ( // Device event notification callback procedure
ULONG iEventStatus ); // Device events and current state (defined in the downlink): 0=Device pull out event, 3=Device insert event

#define CH341_DEVICE_ARRIVAL 3 // Device Insertion Event Inserted
#define CH341_DEVICE_REMOVE_PEND 1 // The device will be pulled out
#define CH341_DEVICE_REMOVE 0 // Device pulls out and has been pulled out


BOOL WINAPI CH341SetDeviceNotify( // Set device event notifier
ULONG iIndex, // Specify CH341 device serial number, 0 corresponds to the first device
PCHAR iDeviceID, // optional argument, points to a string, specifies the ID of the device being monitored, the string ends with \0
mPCH341_NOTIFY_ROUTINE iNotifyRoutine ); // Specifies the device event callback procedure. If NULL, the event notification is cancelled. Otherwise, the program is called when the event is detected.


BOOL WINAPI CH341SetupSerial( // Set the serial port feature of CH341. This API can only be used for CH341 chip working in serial port mode.
ULONG iIndex, // Specify CH341 device serial number, 0 corresponds to the first device
ULONG iParityMode, // Specify the data verification mode of CH341 serial port: NOPARITY/ODDPARITY/EVENPARITY/MARKPARITY/SPACEPARITY
ULONG iBaudRate ); // Specify the communication baud rate of CH341 serial port, it can be any value between 50 and 3000000

/* The following APIs can be used to work on the serial port CH341 chip. In addition, the API can only be used for parallel port CH341 chip.
CH341OpenDevice
CH341CloseDevice
CH341SetupSerial
CH341ReadData
CH341WriteData
CH341SetBufUpload
CH341QueryBufUpload
CH341SetBufDownload
CH341QueryBufDownload
CH341SetDeviceNotify
CH341GetStatus
// The above are the main APIs, the following are the minor APIs
CH341GetVersion
CH341DriverCommand
CH341GetDrvVersion
CH341ResetDevice
CH341GetDeviceDescr
CH341GetConfigDescr
CH341SetIntRoutine
CH341ReadInter
CH341AbortInter
CH341AbortRead
CH341AbortWrite
CH341ReadI2C
CH341WriteI2C
CH341SetExclusive
CH341SetTimeout
CH341GetDeviceName
CH341GetVerIC
CH341FlushBuffer
CH341WriteRead
CH341ResetInter
CH341ResetRead
CH341ResetWrite
*/
HANDLE WINAPI CH341OpenDeviceEx( // Open CH341 device, return handle, error is invalid
    ULONG iIndex ); // Specify CH341 device serial number, 0 corresponds to the first device inserted, 1 corresponds to the inserted second device, in order to save equipment serial number resources, close the device after use

VOID WINAPI CH341CloseDeviceEx( // Turn off the CH341 device
ULONG iIndex ); // Specify CH341 device serial number

PCHAR WINAPI CH341 GetDeviceNameEx (// returns a buffer pointing to the name of the CH341 device, the error returns NULL
ULONG iIndex ); // Specify CH341 device serial number, 0 corresponds to the first device

BOOL WINAPI CH341SetDeviceNotifyEx( // Set device event notifier
ULONG iIndex, // Specify CH341 device serial number, 0 corresponds to the first device
PCHAR iDeviceID, // optional argument, points to a string, specifies the ID of the device being monitored, the string ends with \0
mPCH341_NOTIFY_ROUTINE iNotifyRoutine ); // Specifies the device event callback procedure. If NULL, the event notification is cancelled. Otherwise, the program is called when the event is detected.


#ifdef __cplusplus
}
#endif

#endif // _CH341_DLL_H

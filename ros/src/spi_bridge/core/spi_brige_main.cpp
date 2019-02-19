#include "spi_brige_common.h"
#include "spi_brige_manager.h"

int main(int argc, char **argv)
{
  ros::init(argc, argv, "spi_brige");

  SPIBrigeManager mgr;

  ros::Rate loop_rate(LOOP_RATE);
  while (ros::ok())
  {
    ros::spinOnce();
    mgr.spi_exchange();
    loop_rate.sleep();
  }

  return 0;

}

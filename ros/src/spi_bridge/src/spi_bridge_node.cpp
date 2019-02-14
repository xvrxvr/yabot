#include "ros/ros.h"
#include "spi_bridge/Turn.h"

void turnHeadCallback(const spi_bridge::Turn::ConstPtr& msg)
{
    ROS_INFO("Turn head message: direction=[%d] angle=[%f]", msg->direction, msg->angle);
}

int main(int argc, char **argv)
{
    ros::init(argc, argv, "listener");
    ros::NodeHandle n;
    ros::Subscriber sub = n.subscribe("Head", 8, turnHeadCallback);

    ros::spin();

    return 0;
}

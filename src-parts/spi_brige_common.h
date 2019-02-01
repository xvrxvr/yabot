#pragma once

#include <stdint.h>

#include <ros/ros.h>

#include <deque>
#include <vector>
#include <thread>

constexpr int LOOP_RATE = 30; //processing frequency


// HW setup
constexpr int SPI_QUEUE_SIZE = 8192; // Size of inbound/outbound queue

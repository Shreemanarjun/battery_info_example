package com.example.battery_info_example;

import android.content.Context;
import android.os.BatteryManager;
import android.os.Build;
import androidx.annotation.Keep;

/**
 * Battery information helper class for JNI access.
 *
 * This class provides battery-related information using Android's BatteryManager API.
 * It will be accessed from Dart via JNI using jnigen-generated bindings.
 */
@Keep
public class BatteryInfoJni {
    private Context context;

    public BatteryInfoJni() {
        // Context will be set later via setContext method
        this.context = null;
    }

    // Keep the old constructor for backward compatibility
    public BatteryInfoJni(Context context) {
        this.context = context;
    }

    // Method to set context from Dart side
    public void setContext(Context context) {
        this.context = context;
    }

    /**
     * Get current battery level as percentage (0-100).
     * @return Battery level percentage, or -1 if unavailable
     */
    public int getBatteryLevel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            BatteryManager batteryManager = (BatteryManager) context.getSystemService(Context.BATTERY_SERVICE);
            if (batteryManager != null) {
                return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY);
            }
        }
        return -1;
    }

    /**
     * Check if device is currently charging.
     * @return true if charging, false otherwise
     */
    public boolean isCharging() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            BatteryManager batteryManager = (BatteryManager) context.getSystemService(Context.BATTERY_SERVICE);
            if (batteryManager != null) {
                return batteryManager.isCharging();
            }
        }
        return false;
    }

    /**
     * Get battery temperature in tenths of a degree Celsius.
     * @return Temperature or -1 if unavailable
     */
    public int getTemperature() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            BatteryManager batteryManager = (BatteryManager) context.getSystemService(Context.BATTERY_SERVICE);
            if (batteryManager != null) {
                return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW);
            }
        }
        return -1;
    }
}

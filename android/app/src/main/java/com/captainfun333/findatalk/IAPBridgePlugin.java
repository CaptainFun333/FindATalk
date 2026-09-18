package com.captainfun333.findatalk;

import android.util.Log;

import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.ConsumeParams;
import com.android.billingclient.api.PendingPurchasesParams;
import com.android.billingclient.api.ProductDetails;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.PurchasesUpdatedListener;
import com.android.billingclient.api.QueryProductDetailsParams;
import com.android.billingclient.api.QueryPurchasesParams;
import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import org.json.JSONException;

import java.util.ArrayList;
import java.util.List;

/**
 * Wraps Google Play Billing Library for FindATalk's in-app tip jar. Lives
 * directly in this app module (not a separate local Capacitor package like
 * capacitor-iap-bridge on iOS) because this repo has no existing
 * Capacitor-package-style Android module and no Kotlin toolchain yet — the
 * Play Billing Library's Java API is fine for a plugin this small, so
 * introducing one just for this wasn't worth it. Follows the same
 * hand-registered-in-MainActivity pattern as WidgetRefreshPlugin already
 * does in this file's neighbor.
 *
 * Tips are one-time ("INAPP") consumable products — see the product id
 * list in functions/index.js. A purchase must be consumeAsync()'d (not
 * just acknowledged) or Play Billing will refund it automatically after a
 * few days and the user won't be able to buy the same tip tier again.
 */
@CapacitorPlugin(name = "IAPBridge")
public class IAPBridgePlugin extends Plugin implements PurchasesUpdatedListener {
    private static final String TAG = "IAPBridgePlugin";

    private BillingClient billingClient;
    private boolean billingReady = false;

    // Only one purchase flow can be in flight at a time — launchBillingFlow()
    // returns immediately and the real result arrives later via
    // onPurchasesUpdated(), so the call has to be parked here until then.
    private PluginCall pendingPurchaseCall;
    private String pendingPurchaseProductId;

    @Override
    public void load() {
        billingClient = BillingClient.newBuilder(getContext())
            .setListener(this)
            .enablePendingPurchases(
                PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
            .build();
        connect(null);
    }

    private void connect(Runnable onReady) {
        if (billingReady) {
            if (onReady != null) onReady.run();
            return;
        }
        billingClient.startConnection(new BillingClientStateListener() {
            @Override
            public void onBillingSetupFinished(BillingResult billingResult) {
                billingReady = billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK;
                if (billingReady && onReady != null) onReady.run();
            }

            @Override
            public void onBillingServiceDisconnected() {
                billingReady = false;
            }
        });
    }

    @PluginMethod
    public void getProducts(PluginCall call) {
        JSArray productIds = call.getArray("productIds");
        if (productIds == null || productIds.length() == 0) {
            call.reject("Missing productIds");
            return;
        }
        List<QueryProductDetailsParams.Product> products = new ArrayList<>();
        try {
            for (int i = 0; i < productIds.length(); i++) {
                products.add(QueryProductDetailsParams.Product.newBuilder()
                    .setProductId(productIds.getString(i))
                    .setProductType(BillingClient.ProductType.INAPP)
                    .build());
            }
        } catch (JSONException e) {
            call.reject("Invalid productIds", e);
            return;
        }
        QueryProductDetailsParams params = QueryProductDetailsParams.newBuilder()
            .setProductList(products)
            .build();

        connect(() -> billingClient.queryProductDetailsAsync(params, (billingResult, result) -> {
            if (billingResult.getResponseCode() != BillingClient.BillingResponseCode.OK) {
                call.reject("Failed to load products: " + billingResult.getDebugMessage());
                return;
            }
            JSArray out = new JSArray();
            for (ProductDetails details : result.getProductDetailsList()) {
                JSObject obj = new JSObject();
                obj.put("id", details.getProductId());
                obj.put("displayName", details.getName());
                ProductDetails.OneTimePurchaseOfferDetails offer = details.getOneTimePurchaseOfferDetails();
                obj.put("displayPrice", offer != null ? offer.getFormattedPrice() : "");
                out.put(obj);
            }
            JSObject data = new JSObject();
            data.put("products", out);
            call.resolve(data);
        }));
    }

    @PluginMethod
    public void purchase(PluginCall call) {
        String productId = call.getString("productId");
        if (productId == null) {
            call.reject("Missing productId");
            return;
        }
        if (pendingPurchaseCall != null) {
            call.reject("A purchase is already in progress");
            return;
        }
        QueryProductDetailsParams params = QueryProductDetailsParams.newBuilder()
            .setProductList(List.of(QueryProductDetailsParams.Product.newBuilder()
                .setProductId(productId)
                .setProductType(BillingClient.ProductType.INAPP)
                .build()))
            .build();

        connect(() -> billingClient.queryProductDetailsAsync(params, (billingResult, result) -> {
            if (billingResult.getResponseCode() != BillingClient.BillingResponseCode.OK
                || result.getProductDetailsList().isEmpty()) {
                call.reject("Unknown product: " + productId);
                return;
            }
            ProductDetails details = result.getProductDetailsList().get(0);
            BillingFlowParams flowParams = BillingFlowParams.newBuilder()
                .setProductDetailsParamsList(List.of(
                    BillingFlowParams.ProductDetailsParams.newBuilder()
                        .setProductDetails(details)
                        .build()))
                .build();
            pendingPurchaseCall = call;
            pendingPurchaseProductId = productId;
            BillingResult launchResult = billingClient.launchBillingFlow(getActivity(), flowParams);
            if (launchResult.getResponseCode() != BillingClient.BillingResponseCode.OK) {
                pendingPurchaseCall = null;
                pendingPurchaseProductId = null;
                call.reject("Failed to launch purchase: " + launchResult.getDebugMessage());
            }
        }));
    }

    @Override
    public void onPurchasesUpdated(BillingResult billingResult, List<Purchase> purchases) {
        PluginCall call = pendingPurchaseCall;
        pendingPurchaseCall = null;
        pendingPurchaseProductId = null;
        if (call == null) return; // e.g. a purchase restored outside our own launchBillingFlow

        if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.USER_CANCELED) {
            call.reject("Purchase cancelled", "CANCELLED");
            return;
        }
        if (billingResult.getResponseCode() != BillingClient.BillingResponseCode.OK || purchases == null) {
            call.reject("Purchase failed: " + billingResult.getDebugMessage());
            return;
        }
        Purchase purchase = purchases.get(0);
        call.resolve(purchaseToJSObject(purchase));
    }

    private JSObject purchaseToJSObject(Purchase purchase) {
        JSObject obj = new JSObject();
        obj.put("purchaseToken", purchase.getPurchaseToken());
        obj.put("orderId", purchase.getOrderId());
        obj.put("originalJson", purchase.getOriginalJson());
        obj.put("signature", purchase.getSignature());
        obj.put("productId", purchase.getProducts().isEmpty() ? "" : purchase.getProducts().get(0));
        return obj;
    }

    /** Called only after the Cloud Function confirms it recorded the tip server-side. */
    @PluginMethod
    public void consumePurchase(PluginCall call) {
        String purchaseToken = call.getString("purchaseToken");
        if (purchaseToken == null) {
            call.reject("Missing purchaseToken");
            return;
        }
        ConsumeParams params = ConsumeParams.newBuilder()
            .setPurchaseToken(purchaseToken)
            .build();
        connect(() -> billingClient.consumeAsync(params, (billingResult, token) -> {
            if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK) {
                call.resolve();
            } else {
                call.reject("Failed to consume purchase: " + billingResult.getDebugMessage());
            }
        }));
    }

    /**
     * Called on app resume to catch any purchase that completed at Play but
     * never got consumed on this device (app killed mid-flow, etc.) — the
     * JS side runs each of these back through verify-then-consume.
     */
    @PluginMethod
    public void queryPurchases(PluginCall call) {
        QueryPurchasesParams params = QueryPurchasesParams.newBuilder()
            .setProductType(BillingClient.ProductType.INAPP)
            .build();
        connect(() -> billingClient.queryPurchasesAsync(params, (billingResult, purchases) -> {
            if (billingResult.getResponseCode() != BillingClient.BillingResponseCode.OK) {
                call.reject("Failed to query purchases: " + billingResult.getDebugMessage());
                return;
            }
            JSArray out = new JSArray();
            for (Purchase purchase : purchases) {
                if (purchase.getPurchaseState() == Purchase.PurchaseState.PURCHASED) {
                    out.put(purchaseToJSObject(purchase));
                }
            }
            JSObject data = new JSObject();
            data.put("purchases", out);
            call.resolve(data);
        }));
    }
}

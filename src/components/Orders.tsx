import { useState, useEffect } from 'react';
import { X, Package, Calendar, DollarSign } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';

interface OrderItem {
  id: string;
  quantity: number;
  price: number;
  product: {
    name: string;
    image_url: string;
  } | null;
}

interface Order {
  id: string;
  total: number;
  status: string;
  customer_name: string;
  customer_email: string;
  customer_address: string;
  created_at: string;
  items: OrderItem[];
}

interface OrdersProps {
  isOpen: boolean;
  onClose: () => void;
}

export default function Orders({ isOpen, onClose }: OrdersProps) {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(false);
  const [expandedOrder, setExpandedOrder] = useState<string | null>(null);
  const { user } = useAuth();

  useEffect(() => {
    if (isOpen && user) {
      fetchOrders();
    }
  }, [isOpen, user]);

  const fetchOrders = async () => {
    if (!user) return;

    setLoading(true);
    const { data: ordersData } = await supabase
      .from('orders')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });

    if (ordersData) {
      const ordersWithItems = await Promise.all(
        ordersData.map(async (order) => {
          const { data: items } = await supabase
            .from('order_items')
            .select(`
              id,
              quantity,
              price,
              product:products(name, image_url)
            `)
            .eq('order_id', order.id);

          return { ...order, items: items || [] };
        })
      );
      setOrders(ordersWithItems as any);
    }
    setLoading(false);
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg max-w-4xl w-full max-h-[90vh] overflow-hidden flex flex-col">
        <div className="bg-blue-600 text-white px-6 py-4 flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <Package size={24} />
            <h2 className="text-2xl font-bold">My Orders</h2>
          </div>
          <button
            onClick={onClose}
            className="text-white hover:text-gray-200 transition-colors"
          >
            <X size={24} />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-6">
          {loading ? (
            <div className="flex justify-center py-12">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
            </div>
          ) : orders.length === 0 ? (
            <div className="text-center py-12 text-gray-500">
              <Package className="mx-auto mb-4 text-gray-400" size={48} />
              <p>No orders yet</p>
            </div>
          ) : (
            <div className="space-y-4">
              {orders.map((order) => (
                <div
                  key={order.id}
                  className="border border-gray-200 rounded-lg overflow-hidden hover:shadow-md transition-shadow"
                >
                  <div
                    onClick={() => setExpandedOrder(expandedOrder === order.id ? null : order.id)}
                    className="bg-gray-50 p-4 cursor-pointer"
                  >
                    <div className="flex flex-wrap items-center justify-between gap-4">
                      <div className="flex items-center space-x-4">
                        <div className="bg-blue-100 text-blue-600 p-2 rounded-lg">
                          <Package size={24} />
                        </div>
                        <div>
                          <p className="font-semibold text-gray-800">
                            Order #{order.id.slice(0, 8)}
                          </p>
                          <div className="flex items-center space-x-4 text-sm text-gray-600 mt-1">
                            <span className="flex items-center space-x-1">
                              <Calendar size={14} />
                              <span>{new Date(order.created_at).toLocaleDateString()}</span>
                            </span>
                            <span className="flex items-center space-x-1">
                              <DollarSign size={14} />
                              <span>${order.total.toFixed(2)}</span>
                            </span>
                          </div>
                        </div>
                      </div>
                      <span className="px-3 py-1 bg-yellow-100 text-yellow-800 rounded-full text-sm font-medium">
                        {order.status}
                      </span>
                    </div>
                  </div>

                  {expandedOrder === order.id && (
                    <div className="p-4 space-y-4 bg-white">
                      <div className="grid md:grid-cols-2 gap-4">
                        <div>
                          <h4 className="font-semibold text-gray-700 mb-2">Customer Details</h4>
                          <p className="text-sm text-gray-600">{order.customer_name}</p>
                          <p className="text-sm text-gray-600">{order.customer_email}</p>
                          <p className="text-sm text-gray-600 mt-2">{order.customer_address}</p>
                        </div>
                        <div>
                          <h4 className="font-semibold text-gray-700 mb-2">Order Items</h4>
                          <div className="space-y-2">
                            {order.items.map((item) => (
                              <div key={item.id} className="flex items-center space-x-3 text-sm">
                                {item.product && (
                                  <>
                                    <img
                                      src={item.product.image_url}
                                      alt={item.product.name}
                                      className="w-12 h-12 object-cover rounded"
                                    />
                                    <div className="flex-1">
                                      <p className="text-gray-800">{item.product.name}</p>
                                      <p className="text-gray-600">
                                        Qty: {item.quantity} × ${item.price.toFixed(2)}
                                      </p>
                                    </div>
                                  </>
                                )}
                              </div>
                            ))}
                          </div>
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

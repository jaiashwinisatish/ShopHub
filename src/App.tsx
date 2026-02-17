import { useState, useEffect } from 'react';
import Header from './components/Header';
import ProductCatalog from './components/ProductCatalog';
import ProductDetail from './components/ProductDetail';
import ShoppingCart from './components/ShoppingCart';
import Checkout from './components/Checkout';
import Orders from './components/Orders';
import { useAuth } from './contexts/AuthContext';
import { supabase } from './lib/supabase';

interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  image_url: string;
  category_id: string;
  stock: number;
  featured: boolean;
}

function App() {
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [showCart, setShowCart] = useState(false);
  const [showCheckout, setShowCheckout] = useState(false);
  const [showOrders, setShowOrders] = useState(false);
  const [cartItemCount, setCartItemCount] = useState(0);
  const { user } = useAuth();

  useEffect(() => {
    if (user) {
      updateCartCount();
    } else {
      setCartItemCount(0);
    }
  }, [user]);

  useEffect(() => {
    const handleCartUpdate = () => {
      updateCartCount();
    };
    window.addEventListener('cart-updated', handleCartUpdate);
    return () => window.removeEventListener('cart-updated', handleCartUpdate);
  }, [user]);

  const updateCartCount = async () => {
    if (!user) return;

    const { data } = await supabase
      .from('cart_items')
      .select('quantity')
      .eq('user_id', user.id);

    if (data) {
      const total = data.reduce((sum, item) => sum + item.quantity, 0);
      setCartItemCount(total);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <Header
        onCartClick={() => setShowCart(true)}
        onOrdersClick={() => setShowOrders(true)}
        cartItemCount={cartItemCount}
      />

      <main>
        <ProductCatalog onProductClick={setSelectedProduct} />
      </main>

      <ProductDetail
        product={selectedProduct}
        onClose={() => setSelectedProduct(null)}
      />

      <ShoppingCart
        isOpen={showCart}
        onClose={() => setShowCart(false)}
        onCheckout={() => setShowCheckout(true)}
      />

      <Checkout
        isOpen={showCheckout}
        onClose={() => setShowCheckout(false)}
      />

      <Orders
        isOpen={showOrders}
        onClose={() => setShowOrders(false)}
      />

      <footer className="bg-white border-t mt-12">
        <div className="container mx-auto px-4 py-8">
          <div className="text-center text-gray-600">
            <p className="mb-2">ShopHub - Your One-Stop E-Commerce Solution</p>
            <p className="text-sm">Built with React, TypeScript, Tailwind CSS, and Supabase</p>
          </div>
        </div>
      </footer>
    </div>
  );
}

export default App;

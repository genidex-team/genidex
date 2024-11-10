class Node {
  constructor(val) {
    this.value = val;
    this.left = null;
    this.right = null;
  }
}

class BinarySearchTree {

  constructor() {
    this.root = null; // root node
  }
  
  insertNode(parentNode, newNode) {
    if (newNode.value < parentNode.value) {
      //check the left child
      parentNode.left !== null
        ? this.insertNode(parentNode.left, newNode)
        : (parentNode.left = newNode);
    } else {
      // check the right child
      parentNode.right !== null
        ? this.insertNode(parentNode.right, newNode)
        : (parentNode.right = newNode);
    }
  }

  insert(val) {
    let newNode = new Node(val);
    this.root !== null
      ? this.insertNode(this.root, newNode)
      : (this.root = newNode);
  }

  printNode(node) {
    if (node.left !== null) {
      this.printNode(node.left); // traverse left subtree
    }
    console.log(node.value);
    if (node.right !== null) {
      this.printNode(node.right); // traverse right subtree
    }
  }

  print() {
    this.root !== null
      ? this.printNode(this.root)
      : console.log('No nodes in the tree');
  }

}

let bst1 = new BinarySearchTree();

bst1.insert(50);
bst1.insert(30);
bst1.insert(10);
bst1.insert(40);
bst1.insert(20);
bst1.insert(80);
bst1.insert(70);
bst1.insert(60);
bst1.insert(100);
bst1.insert(90);

bst1.print();